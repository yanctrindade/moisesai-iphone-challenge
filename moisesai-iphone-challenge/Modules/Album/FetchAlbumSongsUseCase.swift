import Foundation

protocol FetchAlbumSongsUseCaseProtocol: Sendable {
    func execute(collectionId: Int) async throws -> [Song]
}

final class FetchAlbumSongsUseCase: FetchAlbumSongsUseCaseProtocol {
    private let networkService: NetworkServiceProtocol

    init(networkService: NetworkServiceProtocol) {
        self.networkService = networkService
    }

    func execute(collectionId: Int) async throws -> [Song] {
        let endpoint = Endpoint.lookupAlbum(collectionId: collectionId)
        let response: iTunesSearchResponse = try await networkService.request(endpoint)

        return response.results
            .filter { $0.wrapperType == "track" }
            .map { Song(from: $0) }
    }
}
