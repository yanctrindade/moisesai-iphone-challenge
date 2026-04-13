import Foundation

protocol SearchSongsUseCaseProtocol: Sendable {
    func execute(term: String, limit: Int, offset: Int) async throws -> [Song]
    func cachedResults(for term: String) async -> [Song]
}

final class SearchSongsUseCase: SearchSongsUseCaseProtocol {
    private let repository: SongsRepositoryProtocol

    init(repository: SongsRepositoryProtocol) {
        self.repository = repository
    }

    func execute(term: String, limit: Int, offset: Int) async throws -> [Song] {
        try await repository.searchSongs(term: term, limit: limit, offset: offset)
    }

    func cachedResults(for term: String) async -> [Song] {
        await repository.getCachedSongs(for: term)
    }
}
