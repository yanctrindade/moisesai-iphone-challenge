import Foundation
@testable import moisesai_iphone_challenge

final class MockSongsRepository: SongsRepositoryProtocol, @unchecked Sendable {
    var searchSongsCallCount = 0
    var searchSongsLastTerm: String?
    var searchSongsLastLimit: Int?
    var searchSongsLastOffset: Int?
    var searchSongsResult: [Song] = []
    var searchSongsError: Error?

    var getCachedSongsCallCount = 0
    var getCachedSongsResult: [Song] = []

    var getRecentlyPlayedCallCount = 0
    var getRecentlyPlayedResult: [Song] = []

    var saveRecentlyPlayedCallCount = 0
    var saveRecentlyPlayedLastSong: Song?

    func searchSongs(term: String, limit: Int, offset: Int) async throws -> [Song] {
        searchSongsCallCount += 1
        searchSongsLastTerm = term
        searchSongsLastLimit = limit
        searchSongsLastOffset = offset

        if let error = searchSongsError {
            throw error
        }
        return searchSongsResult
    }

    func getCachedSongs(for term: String) async -> [Song] {
        getCachedSongsCallCount += 1
        return getCachedSongsResult
    }

    func getRecentlyPlayed() async -> [Song] {
        getRecentlyPlayedCallCount += 1
        return getRecentlyPlayedResult
    }

    func saveRecentlyPlayed(_ song: Song) async {
        saveRecentlyPlayedCallCount += 1
        saveRecentlyPlayedLastSong = song
    }
}
