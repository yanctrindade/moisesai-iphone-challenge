import Testing
@testable import moisesai_iphone_challenge

@Suite("AlbumViewModel Tests")
@MainActor
struct AlbumViewModelTests {

    private func makeSUT() -> (AlbumViewModel, MockFetchAlbumSongsUseCase) {
        let useCase = MockFetchAlbumSongsUseCase()
        let viewModel = AlbumViewModel(
            collectionId: 100,
            collectionName: "Random Access Memories",
            artworkURL: nil,
            fetchAlbumSongsUseCase: useCase
        )
        return (viewModel, useCase)
    }

    // MARK: - Initial State

    @Test func test_initialState_isLoading() {
        let (sut, _) = makeSUT()
        if case .loading = sut.state {} else {
            Issue.record("Expected loading state")
        }
    }

    @Test func test_collectionName_isSet() {
        let (sut, _) = makeSUT()
        #expect(sut.collectionName == "Random Access Memories")
    }

    // MARK: - onAppear

    @Test func test_send_onAppear_fetchesSongs() async throws {
        let (sut, useCase) = makeSUT()
        useCase.executeResult = SongFixture.makeList(count: 5)

        sut.send(.onAppear)
        try await Task.sleep(for: .milliseconds(100))

        #expect(useCase.executeCallCount == 1)
        #expect(useCase.executeLastCollectionId == 100)
        if case .loaded(let songs) = sut.state {
            #expect(songs.count == 5)
        } else {
            Issue.record("Expected loaded state")
        }
    }

    @Test func test_send_onAppear_twice_doesNotRefetch() async throws {
        let (sut, useCase) = makeSUT()
        useCase.executeResult = SongFixture.makeList(count: 3)

        sut.send(.onAppear)
        try await Task.sleep(for: .milliseconds(100))
        sut.send(.onAppear)
        try await Task.sleep(for: .milliseconds(100))

        #expect(useCase.executeCallCount == 1)
    }

    @Test func test_send_onAppear_whenError_setsErrorState() async throws {
        let (sut, useCase) = makeSUT()
        useCase.executeError = NetworkError.noConnection

        sut.send(.onAppear)
        try await Task.sleep(for: .milliseconds(100))

        if case .error = sut.state {} else {
            Issue.record("Expected error state")
        }
    }

    // MARK: - Retry

    @Test func test_send_retry_refetchesAfterError() async throws {
        let (sut, useCase) = makeSUT()
        useCase.executeError = NetworkError.noConnection

        sut.send(.onAppear)
        try await Task.sleep(for: .milliseconds(100))

        useCase.executeError = nil
        useCase.executeResult = SongFixture.makeList(count: 4)

        sut.send(.retry)
        try await Task.sleep(for: .milliseconds(100))

        #expect(useCase.executeCallCount == 2)
        if case .loaded(let songs) = sut.state {
            #expect(songs.count == 4)
        } else {
            Issue.record("Expected loaded state after retry")
        }
    }

    // MARK: - Computed

    @Test func test_artistName_returnsFirstSongArtist() async throws {
        let (sut, useCase) = makeSUT()
        useCase.executeResult = [SongFixture.make(artistName: "Daft Punk")]

        sut.send(.onAppear)
        try await Task.sleep(for: .milliseconds(100))

        #expect(sut.artistName == "Daft Punk")
    }

    @Test func test_artistName_whenNotLoaded_returnsEmpty() {
        let (sut, _) = makeSUT()
        #expect(sut.artistName == "")
    }

    @Test func test_songs_whenLoaded_returnsSongs() async throws {
        let (sut, useCase) = makeSUT()
        useCase.executeResult = SongFixture.makeList(count: 3)

        sut.send(.onAppear)
        try await Task.sleep(for: .milliseconds(100))

        #expect(sut.songs.count == 3)
    }

    @Test func test_songs_whenNotLoaded_returnsEmpty() {
        let (sut, _) = makeSUT()
        #expect(sut.songs.isEmpty)
    }
}
