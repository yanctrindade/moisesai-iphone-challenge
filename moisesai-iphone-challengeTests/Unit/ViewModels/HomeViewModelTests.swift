import Testing
@testable import moisesai_iphone_challenge

@Suite("HomeViewModel Tests")
@MainActor
struct HomeViewModelTests {

    private func makeSUT() -> (HomeViewModel, MockSearchSongsUseCase, MockGetRecentlyPlayedUseCase) {
        let searchUseCase = MockSearchSongsUseCase()
        let recentlyPlayedUseCase = MockGetRecentlyPlayedUseCase()
        let viewModel = HomeViewModel(
            searchSongsUseCase: searchUseCase,
            getRecentlyPlayedUseCase: recentlyPlayedUseCase,
            audioCache: MockAudioCacheService()
        )
        return (viewModel, searchUseCase, recentlyPlayedUseCase)
    }

    // MARK: - Initial State

    @Test func test_initialState_isIdle() {
        let (sut, _, _) = makeSUT()
        if case .idle = sut.state {
            // expected
        } else {
            Issue.record("Expected idle state, got \(sut.state)")
        }
    }

    @Test func test_initialState_recentlyPlayedIsEmpty() {
        let (sut, _, _) = makeSUT()
        #expect(sut.recentlyPlayed.isEmpty)
    }

    // MARK: - onAppear

    @Test func test_send_onAppear_loadsRecentlyPlayed() async throws {
        let (sut, _, recentlyPlayedUseCase) = makeSUT()
        recentlyPlayedUseCase.executeResult = SongFixture.makeList(count: 3)

        sut.send(.onAppear)
        try await Task.sleep(for: .milliseconds(100))

        #expect(sut.recentlyPlayed.count == 3)
        #expect(recentlyPlayedUseCase.executeCallCount == 1)
    }

    // MARK: - Search

    @Test func test_searchText_debouncesThenExecutes() async throws {
        let (sut, searchUseCase, _) = makeSUT()
        searchUseCase.executeResult = SongFixture.makeList(count: 2)

        sut.searchText = "daft punk"
        try await Task.sleep(for: .seconds(1))

        #expect(searchUseCase.executeCallCount == 1)
        #expect(searchUseCase.executeLastTerm == "daft punk")
    }

    @Test func test_searchText_whenResultsFound_stateIsLoaded() async throws {
        let (sut, searchUseCase, _) = makeSUT()
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
        let (sut, searchUseCase, _) = makeSUT()
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
        let (sut, searchUseCase, _) = makeSUT()
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
        let (sut, searchUseCase, _) = makeSUT()
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
        let (sut, searchUseCase, _) = makeSUT()
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
        let (sut, searchUseCase, _) = makeSUT()
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
        let (sut, searchUseCase, _) = makeSUT()
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
        let (sut, searchUseCase, _) = makeSUT()
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
        let (sut, _, recentlyPlayedUseCase) = makeSUT()
        recentlyPlayedUseCase.executeResult = SongFixture.makeList(count: 4)

        await sut.refresh()

        #expect(sut.recentlyPlayed.count == 4)
    }
}
