import Foundation

protocol AudioCacheServiceProtocol: Sendable {
    nonisolated func localURL(for trackId: Int) -> URL?
    nonisolated func hasCache(for trackId: Int) -> Bool
    func cache(remoteURL: URL, trackId: Int) async throws -> URL
    func clearCache() async throws
}
