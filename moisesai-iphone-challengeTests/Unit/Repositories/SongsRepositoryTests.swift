import Testing
import CoreData
@testable import moisesai_iphone_challenge

@Suite("SongsRepository Tests")
struct SongsRepositoryTests {

    private func makeSUT() -> (SongsRepository, MockNetworkService, PersistenceController) {
        let networkService = MockNetworkService()
        let persistence = PersistenceController(inMemory: true)
        let repository = SongsRepository(
            networkService: networkService,
            persistenceController: persistence
        )
        return (repository, networkService, persistence)
    }

    @Test func test_searchSongs_callsNetworkAndReturnsSongs() async throws {
        let (sut, networkService, _) = makeSUT()
        let response = iTunesSearchResponseFixture.make(
            results: [iTunesTrackFixture.make(trackName: "Purple Rain")]
        )
        networkService.resultData = response

        let songs = try await sut.searchSongs(term: "prince", limit: 20, offset: 0)

        #expect(songs.count == 1)
        #expect(songs.first?.trackName == "Purple Rain")
        #expect(networkService.requestCallCount == 1)
    }

    @Test func test_searchSongs_filtersNonTrackResults() async throws {
        let (sut, networkService, _) = makeSUT()
        let response = iTunesSearchResponseFixture.make(
            results: [
                iTunesTrackFixture.make(trackName: "Song", wrapperType: "track"),
                iTunesTrackFixture.make(trackId: 2, trackName: "Artist", wrapperType: "artist")
            ]
        )
        networkService.resultData = response

        let songs = try await sut.searchSongs(term: "test", limit: 20, offset: 0)

        #expect(songs.count == 1)
        #expect(songs.first?.trackName == "Song")
    }

    @Test func test_searchSongs_cachesResultsInCoreData() async throws {
        let (sut, networkService, persistence) = makeSUT()
        let response = iTunesSearchResponseFixture.make(
            results: [iTunesTrackFixture.make(trackName: "Cached Song")]
        )
        networkService.resultData = response

        _ = try await sut.searchSongs(term: "cache test", limit: 20, offset: 0)

        // Allow background context to save
        try await Task.sleep(for: .milliseconds(100))

        let cached = await sut.getCachedSongs(for: "cache test")
        #expect(cached.count == 1)
        #expect(cached.first?.trackName == "Cached Song")
    }

    @Test func test_searchSongs_whenNetworkFails_throwsError() async {
        let (sut, networkService, _) = makeSUT()
        networkService.error = NetworkError.noConnection

        do {
            _ = try await sut.searchSongs(term: "test", limit: 20, offset: 0)
            Issue.record("Expected error")
        } catch {
            #expect(error is NetworkError)
        }
    }

    @Test func test_getCachedSongs_whenEmpty_returnsEmptyArray() async {
        let (sut, _, _) = makeSUT()

        let cached = await sut.getCachedSongs(for: "nonexistent")

        #expect(cached.isEmpty)
    }

    @Test func test_getRecentlyPlayed_whenEmpty_returnsEmptyArray() async {
        let (sut, _, _) = makeSUT()

        let result = await sut.getRecentlyPlayed()

        #expect(result.isEmpty)
    }

    @Test func test_saveRecentlyPlayed_persistsSong() async throws {
        let (sut, _, _) = makeSUT()
        let song = SongFixture.make(trackName: "Recently Played")

        await sut.saveRecentlyPlayed(song)

        // Allow background context to save
        try await Task.sleep(for: .milliseconds(100))

        let result = await sut.getRecentlyPlayed()
        #expect(result.count == 1)
        #expect(result.first?.trackName == "Recently Played")
    }

    @Test func test_saveRecentlyPlayed_updateExisting_doesNotDuplicate() async throws {
        let (sut, _, _) = makeSUT()
        let song = SongFixture.make(id: 42, trackName: "Same Song")

        await sut.saveRecentlyPlayed(song)
        await sut.saveRecentlyPlayed(song)

        try await Task.sleep(for: .milliseconds(100))

        let result = await sut.getRecentlyPlayed()
        #expect(result.count == 1)
    }
}
