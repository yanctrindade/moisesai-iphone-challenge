import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var router = Router()
    @Environment(\.modelContext) private var modelContext
    @Environment(NetworkMonitor.self) private var networkMonitor

    private let networkService = URLSessionNetworkService()

    var body: some View {
        NavigationStack(path: $router.path) {
            HomeView(viewModel: makeHomeViewModel())
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .home:
                        HomeView(viewModel: makeHomeViewModel())
                    case .player(let song, let playlist):
                        makePlayerView(song: song, playlist: playlist)
                    case .album(let collectionId, let collectionName, let artworkURL):
                        makeAlbumView(collectionId: collectionId, collectionName: collectionName, artworkURL: artworkURL)
                    }
                }
        }
        .environment(router)
        .offlineBanner()
    }

    private func makeHomeViewModel() -> HomeViewModel {
        let repository = SongsRepository(networkService: networkService, modelContainer: modelContext.container)
        let searchUseCase = SearchSongsUseCase(repository: repository)
        let recentlyPlayedUseCase = GetRecentlyPlayedUseCase(repository: repository)
        return HomeViewModel(
            searchSongsUseCase: searchUseCase,
            getRecentlyPlayedUseCase: recentlyPlayedUseCase
        )
    }

    private func makeAlbumView(collectionId: Int, collectionName: String, artworkURL: URL?) -> AlbumView {
        let useCase = FetchAlbumSongsUseCase(networkService: networkService)
        return AlbumView(
            viewModel: AlbumViewModel(
                collectionId: collectionId,
                collectionName: collectionName,
                artworkURL: artworkURL,
                fetchAlbumSongsUseCase: useCase
            )
        )
    }

    private func makePlayerView(song: Song, playlist: [Song]) -> PlayerView {
        let repository = SongsRepository(networkService: networkService, modelContainer: modelContext.container)
        let saveRecentlyPlayedUseCase = SaveRecentlyPlayedUseCase(repository: repository)
        return PlayerView(
            viewModel: PlayerViewModel(
                song: song,
                playlist: playlist,
                audioPlayer: AudioPlayerService.shared,
                saveRecentlyPlayedUseCase: saveRecentlyPlayedUseCase,
                networkMonitor: networkMonitor
            )
        )
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [CachedSong.self, RecentlyPlayedSong.self], inMemory: true)
        .preferredColorScheme(.dark)
}
