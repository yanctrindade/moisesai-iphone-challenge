import Foundation
import os

private let logger = Logger(subsystem: "com.yantrindade.moisesai", category: "AudioCacheService")

actor AudioCacheService: AudioCacheServiceProtocol {
    static let shared = AudioCacheService()

    private let fileManager: FileManager
    private let cacheDirectory: URL
    private let maxCacheSize: Int64 = 100 * 1024 * 1024 // 100MB
    private let fileExtension = "m4a"

    /// Tracks in-flight download tasks keyed by trackId to prevent concurrent duplicate downloads
    private var inFlightDownloads: [Int: Task<URL, Error>] = [:]

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        self.cacheDirectory = caches.appendingPathComponent("AudioCache", isDirectory: true)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    nonisolated func localURL(for trackId: Int) -> URL? {
        let url = Self.buildCacheURL(for: trackId, fileManager: .default, fileExtension: "m4a")
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    nonisolated func hasCache(for trackId: Int) -> Bool {
        let url = Self.buildCacheURL(for: trackId, fileManager: .default, fileExtension: "m4a")
        return FileManager.default.fileExists(atPath: url.path)
    }

    func cache(remoteURL: URL, trackId: Int) async throws -> URL {
        let localURL = cacheURL(for: trackId)

        // Already cached
        if fileManager.fileExists(atPath: localURL.path) {
            return localURL
        }

        // Deduplicate concurrent downloads for the same trackId
        if let existing = inFlightDownloads[trackId] {
            return try await existing.value
        }

        let task = Task<URL, Error> { [weak self] in
            guard let self else {
                throw URLError(.cancelled)
            }
            return try await self.performDownload(remoteURL: remoteURL, trackId: trackId)
        }

        inFlightDownloads[trackId] = task

        do {
            let result = try await task.value
            inFlightDownloads[trackId] = nil
            return result
        } catch {
            inFlightDownloads[trackId] = nil
            throw error
        }
    }

    func clearCache() async throws {
        let contents = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
        for url in contents {
            try fileManager.removeItem(at: url)
        }
    }

    // MARK: - Private

    private func performDownload(remoteURL: URL, trackId: Int) async throws -> URL {
        let localURL = cacheURL(for: trackId)
        let (tempURL, _) = try await URLSession.shared.download(from: remoteURL)

        // Re-check after await: another task may have completed while we were suspended
        if fileManager.fileExists(atPath: localURL.path) {
            try? fileManager.removeItem(at: tempURL)
            return localURL
        }

        try fileManager.moveItem(at: tempURL, to: localURL)
        logger.info("Cached audio for trackId \(trackId)")

        evictIfNeeded()

        return localURL
    }

    private func cacheURL(for trackId: Int) -> URL {
        cacheDirectory.appendingPathComponent("\(trackId).\(fileExtension)")
    }

    /// Static helper for nonisolated methods that can't touch actor state.
    /// Keeps the URL-building logic in one place; the directory name ("AudioCache") and extension are shared with `init`.
    private static func buildCacheURL(for trackId: Int, fileManager: FileManager, fileExtension: String) -> URL {
        let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let directory = caches.appendingPathComponent("AudioCache", isDirectory: true)
        return directory.appendingPathComponent("\(trackId).\(fileExtension)")
    }

    private func evictIfNeeded() {
        guard let contents = try? fileManager.contentsOfDirectory(
            at: cacheDirectory,
            includingPropertiesForKeys: [.fileSizeKey, .contentAccessDateKey]
        ) else { return }

        let totalSize = contents.reduce(Int64(0)) { sum, url in
            let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            return sum + Int64(size)
        }

        guard totalSize > maxCacheSize else { return }

        // LRU: sort by access date, remove oldest until under limit
        let sorted = contents.sorted { lhs, rhs in
            let l = (try? lhs.resourceValues(forKeys: [.contentAccessDateKey]).contentAccessDate) ?? .distantPast
            let r = (try? rhs.resourceValues(forKeys: [.contentAccessDateKey]).contentAccessDate) ?? .distantPast
            return l < r
        }

        var currentSize = totalSize
        for url in sorted where currentSize > maxCacheSize {
            let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            try? fileManager.removeItem(at: url)
            currentSize -= Int64(size)
        }
    }
}
