import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var router = Router()
    @Environment(\.modelContext) private var modelContext
    @Environment(NetworkMonitor.self) private var networkMonitor
    @State private var isBannerDismissed = false

    private let networkService = URLSessionNetworkService()

    private var showBanner: Bool {
        !networkMonitor.isConnected && !isBannerDismissed
    }

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
        .overlay(alignment: .bottom) {
            OfflineBanner(isVisible: showBanner) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isBannerDismissed = true
                }
            }
            .padding(.bottom, Spacing.sm)
            .animation(.easeInOut(duration: 0.3), value: showBanner)
        }
        .onChange(of: networkMonitor.isConnected) { _, connected in
            // Reset dismissal when connection state changes
            if !connected {
                isBannerDismissed = false
            }
        }
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
                saveRecentlyPlayedUseCase: saveRecentlyPlayedUseCase
            )
        )
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [CachedSong.self, RecentlyPlayedSong.self], inMemory: true)
        .preferredColorScheme(.dark)
}
