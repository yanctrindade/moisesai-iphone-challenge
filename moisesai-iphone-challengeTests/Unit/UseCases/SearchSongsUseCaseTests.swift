import Testing
@testable import moisesai_iphone_challenge

@Suite("SearchSongsUseCase Tests")
struct SearchSongsUseCaseTests {

    private func makeSUT() -> (SearchSongsUseCase, MockSongsRepository) {
        let repository = MockSongsRepository()
        let useCase = SearchSongsUseCase(repository: repository)
        return (useCase, repository)
    }

    @Test func test_execute_callsRepositoryWithCorrectParams() async throws {
        let (sut, repository) = makeSUT()
        repository.searchSongsResult = SongFixture.makeList(count: 3)

        _ = try await sut.execute(term: "daft punk", limit: 20, offset: 10)

        #expect(repository.searchSongsCallCount == 1)
        #expect(repository.searchSongsLastTerm == "daft punk")
        #expect(repository.searchSongsLastLimit == 20)
        #expect(repository.searchSongsLastOffset == 10)
    }

    @Test func test_execute_returnsRepositoryResults() async throws {
        let (sut, repository) = makeSUT()
        let songs = SongFixture.makeList(count: 3)
        repository.searchSongsResult = songs

        let result = try await sut.execute(term: "test", limit: 20, offset: 0)

        #expect(result.count == 3)
        #expect(result[0].trackName == "Song 1")
    }

    @Test func test_execute_whenRepositoryThrows_propagatesError() async {
        let (sut, repository) = makeSUT()
        repository.searchSongsError = NetworkError.noConnection

        do {
            _ = try await sut.execute(term: "test", limit: 20, offset: 0)
            Issue.record("Expected error")
        } catch {
            #expect(error is NetworkError)
        }
    }

    @Test func test_cachedResults_callsRepository() async {
        let (sut, repository) = makeSUT()
        let songs = SongFixture.makeList(count: 2)
        repository.getCachedSongsResult = songs

        let result = await sut.cachedResults(for: "test")

        #expect(result.count == 2)
        #expect(repository.getCachedSongsCallCount == 1)
    }
}
