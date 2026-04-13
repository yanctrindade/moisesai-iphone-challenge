import Foundation

protocol SaveRecentlyPlayedUseCaseProtocol: Sendable {
    func execute(_ song: Song) async
}

final class SaveRecentlyPlayedUseCase: SaveRecentlyPlayedUseCaseProtocol {
    private let repository: SongsRepositoryProtocol

    init(repository: SongsRepositoryProtocol) {
        self.repository = repository
    }

    func execute(_ song: Song) async {
        await repository.saveRecentlyPlayed(song)
    }
}
