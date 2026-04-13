import Foundation
import os

private let logger = Logger(subsystem: "com.yantrindade.moisesai", category: "AudioCacheService")

actor AudioCacheService: AudioCacheServiceProtocol {
    static let shared = AudioCacheService()

    private let fileManager: FileManager
    private let cacheDirectory: URL
    private let maxCacheSize: Int64 = 100 * 1024 * 1024 // 100MB
    private let fileExtension = "m4a"

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        self.cacheDirectory = caches.appendingPathComponent("AudioCache", isDirectory: true)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    nonisolated func localURL(for trackId: Int) -> URL? {
        let url = cacheURL(for: trackId)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    nonisolated func hasCache(for trackId: Int) -> Bool {
        FileManager.default.fileExists(atPath: cacheURL(for: trackId).path)
    }

    func cache(remoteURL: URL, trackId: Int) async throws -> URL {
        let localURL = cacheURL(for: trackId)

        if fileManager.fileExists(atPath: localURL.path) {
            return localURL
        }

        let (tempURL, _) = try await URLSession.shared.download(from: remoteURL)

        if fileManager.fileExists(atPath: localURL.path) {
            try fileManager.removeItem(at: localURL)
        }

        try fileManager.moveItem(at: tempURL, to: localURL)
        logger.info("Cached audio for trackId \(trackId)")

        evictIfNeeded()

        return localURL
    }

    func clearCache() throws {
        let contents = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
        for url in contents {
            try fileManager.removeItem(at: url)
        }
    }

    // MARK: - Private

    nonisolated private func cacheURL(for trackId: Int) -> URL {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
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
