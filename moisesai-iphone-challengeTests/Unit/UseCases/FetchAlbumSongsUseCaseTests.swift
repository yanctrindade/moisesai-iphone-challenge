import Testing
import Foundation
@testable import moisesai_iphone_challenge

@Suite("FetchAlbumSongsUseCase Tests")
struct FetchAlbumSongsUseCaseTests {

    private func makeSUT() -> (FetchAlbumSongsUseCase, MockNetworkService) {
        let networkService = MockNetworkService()
        let useCase = FetchAlbumSongsUseCase(networkService: networkService)
        return (useCase, networkService)
    }

    @Test func test_execute_callsNetworkWithCorrectEndpoint() async throws {
        let (sut, networkService) = makeSUT()
        networkService.resultData = iTunesSearchResponseFixture.make()

        _ = try await sut.execute(collectionId: 12345)

        #expect(networkService.requestCallCount == 1)
        let url = networkService.lastEndpoint?.url?.absoluteString
        #expect(url?.contains("lookup") == true)
        #expect(url?.contains("id=12345") == true)
        #expect(url?.contains("entity=song") == true)
    }

    @Test func test_execute_filtersToTracksOnly() async throws {
        let (sut, networkService) = makeSUT()
        let response = iTunesSearchResponseFixture.make(results: [
            iTunesTrackFixture.make(trackId: 1, trackName: "Track", wrapperType: "track"),
            iTunesTrackFixture.make(trackId: 2, trackName: "Collection", wrapperType: "collection"),
            iTunesTrackFixture.make(trackId: 3, trackName: "Artist", wrapperType: "artist")
        ])
        networkService.resultData = response

        let songs = try await sut.execute(collectionId: 100)

        #expect(songs.count == 1)
        #expect(songs.first?.trackName == "Track")
    }

    @Test func test_execute_mapsToSongDomain() async throws {
        let (sut, networkService) = makeSUT()
        let response = iTunesSearchResponseFixture.make(results: [
            iTunesTrackFixture.make(
                trackId: 42,
                trackName: "Get Lucky",
                artistName: "Daft Punk",
                wrapperType: "track"
            )
        ])
        networkService.resultData = response

        let songs = try await sut.execute(collectionId: 100)

        #expect(songs.first?.id == 42)
        #expect(songs.first?.trackName == "Get Lucky")
        #expect(songs.first?.artistName == "Daft Punk")
    }

    @Test func test_execute_whenNetworkFails_throwsError() async {
        let (sut, networkService) = makeSUT()
        networkService.error = NetworkError.noConnection

        do {
            _ = try await sut.execute(collectionId: 100)
            Issue.record("Expected error")
        } catch {
            #expect(error is NetworkError)
        }
    }

    @Test func test_execute_whenEmptyResults_returnsEmptyArray() async throws {
        let (sut, networkService) = makeSUT()
        networkService.resultData = iTunesSearchResponseFixture.make(results: [])

        let songs = try await sut.execute(collectionId: 100)

        #expect(songs.isEmpty)
    }
}
