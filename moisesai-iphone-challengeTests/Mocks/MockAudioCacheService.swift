import Foundation
@testable import moisesai_iphone_challenge

final class MockAudioCacheService: AudioCacheServiceProtocol, @unchecked Sendable {
    var cachedTrackIds: Set<Int> = []
    var cacheCallCount = 0
    var cacheLastTrackId: Int?
    var cacheError: Error?

    func localURL(for trackId: Int) -> URL? {
        guard cachedTrackIds.contains(trackId) else { return nil }
        return URL(fileURLWithPath: "/tmp/mock/\(trackId).m4a")
    }

    func hasCache(for trackId: Int) -> Bool {
        cachedTrackIds.contains(trackId)
    }

    func cache(remoteURL: URL, trackId: Int) async throws -> URL {
        cacheCallCount += 1
        cacheLastTrackId = trackId

        if let error = cacheError {
            throw error
        }

        cachedTrackIds.insert(trackId)
        return URL(fileURLWithPath: "/tmp/mock/\(trackId).m4a")
    }

    func clearCache() async throws {
        cachedTrackIds.removeAll()
    }
}
