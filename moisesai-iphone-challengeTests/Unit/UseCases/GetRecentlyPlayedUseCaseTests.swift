import Testing
@testable import moisesai_iphone_challenge

@Suite("GetRecentlyPlayedUseCase Tests")
struct GetRecentlyPlayedUseCaseTests {

    private func makeSUT() -> (GetRecentlyPlayedUseCase, MockSongsRepository) {
        let repository = MockSongsRepository()
        let useCase = GetRecentlyPlayedUseCase(repository: repository)
        return (useCase, repository)
    }

    @Test func test_execute_callsRepository() async {
        let (sut, repository) = makeSUT()
        repository.getRecentlyPlayedResult = SongFixture.makeList(count: 3)

        let result = await sut.execute()

        #expect(result.count == 3)
        #expect(repository.getRecentlyPlayedCallCount == 1)
    }

    @Test func test_execute_whenEmpty_returnsEmptyArray() async {
        let (sut, repository) = makeSUT()
        repository.getRecentlyPlayedResult = []

        let result = await sut.execute()

        #expect(result.isEmpty)
    }
}
