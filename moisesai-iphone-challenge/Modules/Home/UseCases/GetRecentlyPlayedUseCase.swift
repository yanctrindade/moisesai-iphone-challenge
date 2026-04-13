import Foundation

protocol GetRecentlyPlayedUseCaseProtocol: Sendable {
    func execute() async -> [Song]
}

final class GetRecentlyPlayedUseCase: GetRecentlyPlayedUseCaseProtocol {
    private let repository: SongsRepositoryProtocol

    init(repository: SongsRepositoryProtocol) {
        self.repository = repository
    }

    func execute() async -> [Song] {
        await repository.getRecentlyPlayed()
    }
}
