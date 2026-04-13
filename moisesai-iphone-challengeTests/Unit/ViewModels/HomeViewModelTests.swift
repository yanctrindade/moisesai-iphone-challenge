import Testing
@testable import moisesai_iphone_challenge

@Suite("HomeViewModel Tests")
@MainActor
struct HomeViewModelTests {

    private func makeSUT(
        audioCache: MockAudioCacheService = MockAudioCacheService()
    ) -> (HomeViewModel, MockSearchSongsUseCase, MockGetRecentlyPlayedUseCase, MockAudioCacheService) {
        let searchUseCase = MockSearchSongsUseCase()
        let recentlyPlayedUseCase = MockGetRecentlyPlayedUseCase()
        let viewModel = HomeViewModel(
            searchSongsUseCase: searchUseCase,
            getRecentlyPlayedUseCase: recentlyPlayedUseCase,
            audioCache: audioCache
        )
        return (viewModel, searchUseCase, recentlyPlayedUseCase, audioCache)
    }

    // MARK: - Initial State

    @Test func test_initialState_isIdle() {
        let (sut, _, _, _) = makeSUT()
        if case .idle = sut.state {
            // expected
        } else {
            Issue.record("Expected idle state, got \(sut.state)")
        }
    }

    @Test func test_initialState_recentlyPlayedIsEmpty() {
        let (sut, _, _, _) = makeSUT()
        #expect(sut.recentlyPlayed.isEmpty)
    }

    // MARK: - onAppear

    @Test func test_send_onAppear_loadsRecentlyPlayed() async throws {
        let (sut, _, recentlyPlayedUseCase, _) = makeSUT()
        recentlyPlayedUseCase.executeResult = SongFixture.makeList(count: 3)

        sut.send(.onAppear)
        try await Task.sleep(for: .milliseconds(100))

        #expect(sut.recentlyPlayed.count == 3)
        #expect(recentlyPlayedUseCase.executeCallCount == 1)
    }

    // MARK: - Search

    @Test func test_searchText_debouncesThenExecutes() async throws {
        let (sut, searchUseCase, _, _) = makeSUT()
        searchUseCase.executeResult = SongFixture.makeList(count: 2)

        sut.searchText = "daft punk"
        try await Task.sleep(for: .seconds(1))

        #expect(searchUseCase.executeCallCount == 1)
        #expect(searchUseCase.executeLastTerm == "daft punk")
    }

    @Test func test_searchText_whenResultsFound_stateIsLoaded() async throws {
        let (sut, searchUseCase, _, _) = makeSUT()
        let songs = SongFixture.makeList(count: 3)
        searchUseCase.executeResult = songs

        sut.searchText = "test"
        try await Task.sleep(for: .seconds(1))

        if case .loaded(let loadedSongs) = sut.state {
            #expect(loadedSongs.count == 3)
        } else {
            Issue.record("Expected loaded state, got \(sut.state)")
        }
    }

    @Test func test_searchText_whenEmpty_stateIsIdle() async throws {
        let (sut, searchUseCase, _, _) = makeSUT()
        searchUseCase.executeResult = SongFixture.makeList(count: 2)

        sut.searchText = "test"
        try await Task.sleep(for: .seconds(1))

        sut.searchText = ""
        try await Task.sleep(for: .milliseconds(100))

        if case .idle = sut.state {
            // expected
        } else {
            Issue.record("Expected idle state after clearing search")
        }
    }

    @Test func test_searchText_whenError_stateIsError() async throws {
        let (sut, searchUseCase, _, _) = makeSUT()
        searchUseCase.executeError = NetworkError.noConnection

        sut.searchText = "test"
        try await Task.sleep(for: .seconds(1))

        if case .error = sut.state {
            // expected
        } else {
            Issue.record("Expected error state, got \(sut.state)")
        }
    }

    @Test func test_searchText_showsCachedResultsFirst() async throws {
        let (sut, searchUseCase, _, _) = makeSUT()
        let cached = SongFixture.makeList(count: 2)
        searchUseCase.cachedResultsResult = cached
        searchUseCase.executeResult = SongFixture.makeList(count: 5)

        sut.searchText = "cached"
        try await Task.sleep(for: .seconds(1))

        // After full execution, should show fresh results
        if case .loaded(let songs) = sut.state {
            #expect(songs.count == 5)
        } else {
            Issue.record("Expected loaded state")
        }
        #expect(searchUseCase.cachedResultsCallCount == 1)
    }

    // MARK: - Clear Search

    @Test func test_send_clearSearch_resetsState() async throws {
        let (sut, searchUseCase, _, _) = makeSUT()
        searchUseCase.executeResult = SongFixture.makeList(count: 3)

        sut.searchText = "test"
        try await Task.sleep(for: .seconds(1))

        sut.send(.clearSearch)

        if case .idle = sut.state {
            // expected
        } else {
            Issue.record("Expected idle state after clear")
        }
    }

    // MARK: - Load More (Pagination)

    @Test func test_send_loadMore_appendsResults() async throws {
        let (sut, searchUseCase, _, _) = makeSUT()
        let firstPage = SongFixture.makeList(count: 20)
        searchUseCase.executeResult = firstPage

        sut.searchText = "test"
        try await Task.sleep(for: .seconds(1))

        let secondPage = (20..<25).map { SongFixture.make(id: $0, trackName: "Song \($0)") }
        searchUseCase.executeResult = secondPage

        sut.send(.loadMore)
        try await Task.sleep(for: .milliseconds(200))

        if case .loaded(let songs) = sut.state {
            #expect(songs.count == 25)
        } else {
            Issue.record("Expected loaded state with appended results")
        }
    }

    @Test func test_send_loadMore_whenNoMorePages_doesNothing() async throws {
        let (sut, searchUseCase, _, _) = makeSUT()
        // Less than page size = no more pages
        searchUseCase.executeResult = SongFixture.makeList(count: 5)

        sut.searchText = "test"
        try await Task.sleep(for: .seconds(1))

        let callCountBefore = searchUseCase.executeCallCount
        sut.send(.loadMore)
        try await Task.sleep(for: .milliseconds(200))

        #expect(searchUseCase.executeCallCount == callCountBefore)
    }

    // MARK: - Refresh

    @Test func test_refresh_reloadsCurrentSearch() async throws {
        let (sut, searchUseCase, _, _) = makeSUT()
        searchUseCase.executeResult = SongFixture.makeList(count: 3)

        sut.searchText = "test"
        try await Task.sleep(for: .seconds(1))

        let refreshed = SongFixture.makeList(count: 5)
        searchUseCase.executeResult = refreshed

        await sut.refresh()

        if case .loaded(let songs) = sut.state {
            #expect(songs.count == 5)
        } else {
            Issue.record("Expected loaded state after refresh")
        }
    }

    @Test func test_refresh_whenNoSearch_loadsRecentlyPlayed() async throws {
        let (sut, _, recentlyPlayedUseCase, _) = makeSUT()
        recentlyPlayedUseCase.executeResult = SongFixture.makeList(count: 4)

        await sut.refresh()

        #expect(sut.recentlyPlayed.count == 4)
    }

    // MARK: - Cached Track IDs

    @Test func test_onAppear_populatesCachedTrackIds() async throws {
        let cache = MockAudioCacheService()
        cache.cachedTrackIds = [1, 3]
        let (sut, _, recentlyPlayedUseCase, _) = makeSUT(audioCache: cache)
        recentlyPlayedUseCase.executeResult = SongFixture.makeList(count: 5)

        sut.send(.onAppear)
        try await Task.sleep(for: .milliseconds(100))

        #expect(sut.cachedTrackIds == [1, 3])
        #expect(sut.isCached(SongFixture.make(id: 1)) == true)
        #expect(sut.isCached(SongFixture.make(id: 2)) == false)
    }

    @Test func test_search_populatesCachedTrackIds() async throws {
        let cache = MockAudioCacheService()
        cache.cachedTrackIds = [2]
        let (sut, searchUseCase, _, _) = makeSUT(audioCache: cache)
        searchUseCase.executeResult = SongFixture.makeList(count: 3)

        sut.searchText = "test"
        try await Task.sleep(for: .seconds(1))

        #expect(sut.cachedTrackIds == [2])
    }

    @Test func test_clearSearch_refreshesCachedTrackIds() async throws {
        let cache = MockAudioCacheService()
        cache.cachedTrackIds = [1]
        let (sut, searchUseCase, recentlyPlayedUseCase, _) = makeSUT(audioCache: cache)
        recentlyPlayedUseCase.executeResult = [SongFixture.make(id: 1)]
        searchUseCase.executeResult = [SongFixture.make(id: 5)]

        sut.send(.onAppear)
        try await Task.sleep(for: .milliseconds(100))
        #expect(sut.cachedTrackIds == [1])

        sut.searchText = "test"
        try await Task.sleep(for: .seconds(1))

        sut.send(.clearSearch)
        // After clearSearch, cachedTrackIds only reflects recentlyPlayed (songs list cleared)
        #expect(sut.cachedTrackIds == [1])
    }

    @Test func test_loadMore_refreshesCachedTrackIds() async throws {
        let cache = MockAudioCacheService()
        let (sut, searchUseCase, _, _) = makeSUT(audioCache: cache)

        // First page
        searchUseCase.executeResult = SongFixture.makeList(count: 20)
        sut.searchText = "test"
        try await Task.sleep(for: .seconds(1))

        // Mark a new song as cached before pagination
        cache.cachedTrackIds = [25]
        searchUseCase.executeResult = [SongFixture.make(id: 25)]
        sut.send(.loadMore)
        try await Task.sleep(for: .milliseconds(200))

        #expect(sut.cachedTrackIds.contains(25))
    }
}
