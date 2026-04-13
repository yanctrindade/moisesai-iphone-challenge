import Foundation
import SwiftData

/// Shared dependencies for the app — single source of truth for services and repositories.
/// Created once at app launch, passed down to views that need to construct ViewModels.
@MainActor
struct AppDependencies {
    let networkService: NetworkServiceProtocol
    let audioPlayer: AudioPlayerServiceProtocol
    let audioCache: AudioCacheServiceProtocol
    let networkMonitor: NetworkMonitorProtocol
    let modelContainer: ModelContainer

    var songsRepository: SongsRepositoryProtocol {
        SongsRepository(networkService: networkService, modelContainer: modelContainer)
    }

    static func live(modelContainer: ModelContainer, networkMonitor: NetworkMonitorProtocol) -> AppDependencies {
        AppDependencies(
            networkService: URLSessionNetworkService(),
            audioPlayer: AudioPlayerService.shared,
            audioCache: AudioCacheService.shared,
            networkMonitor: networkMonitor,
            modelContainer: modelContainer
        )
    }
}
