import SwiftUI
import SwiftData

struct ContentView: View {
    let deps: AppDependencies

    @State private var router = Router()
    @State private var homeViewModel: HomeViewModel

    init(deps: AppDependencies) {
        self.deps = deps
        let repository = deps.songsRepository
        _homeViewModel = State(
            initialValue: HomeViewModel(
                searchSongsUseCase: SearchSongsUseCase(repository: repository),
                getRecentlyPlayedUseCase: GetRecentlyPlayedUseCase(repository: repository)
            )
        )
    }

    var body: some View {
        NavigationStack(path: $router.path) {
            HomeView(viewModel: homeViewModel)
                .navigationDestination(for: Route.self) { route in
                    destinationView(for: route)
                }
        }
        .environment(router)
        .offlineBanner()
    }

    @ViewBuilder
    private func destinationView(for route: Route) -> some View {
        switch route {
        case .home:
            HomeView(viewModel: homeViewModel)
        case .player(let song, let playlist):
            makePlayerView(song: song, playlist: playlist)
        case .album(let collectionId, let collectionName, let artworkURL):
            makeAlbumView(collectionId: collectionId, collectionName: collectionName, artworkURL: artworkURL)
        }
    }

    private func makeAlbumView(collectionId: Int, collectionName: String, artworkURL: URL?) -> AlbumView {
        AlbumView(
            viewModel: AlbumViewModel(
                collectionId: collectionId,
                collectionName: collectionName,
                artworkURL: artworkURL,
                fetchAlbumSongsUseCase: FetchAlbumSongsUseCase(networkService: deps.networkService)
            )
        )
    }

    private func makePlayerView(song: Song, playlist: [Song]) -> PlayerView {
        PlayerView(
            viewModel: PlayerViewModel(
                song: song,
                playlist: playlist,
                audioPlayer: deps.audioPlayer,
                saveRecentlyPlayedUseCase: SaveRecentlyPlayedUseCase(repository: deps.songsRepository),
                audioCache: deps.audioCache,
                networkMonitor: deps.networkMonitor
            )
        )
    }
}

#Preview {
    let container = try! ModelContainer(
        for: CachedSong.self, RecentlyPlayedSong.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let monitor = NetworkMonitor()
    let deps = AppDependencies.live(modelContainer: container, networkMonitor: monitor)

    ContentView(deps: deps)
        .environment(monitor as NetworkMonitor)
        .preferredColorScheme(.dark)
}
