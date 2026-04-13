import SwiftUI

struct ContentView: View {
    @State private var router = Router()

    private let networkService = URLSessionNetworkService()

    @State private var homeViewModel: HomeViewModel = {
        let networkService = URLSessionNetworkService()
        let repository = SongsRepository(networkService: networkService)
        let searchUseCase = SearchSongsUseCase(repository: repository)
        let recentlyPlayedUseCase = GetRecentlyPlayedUseCase(repository: repository)
        return HomeViewModel(
            searchSongsUseCase: searchUseCase,
            getRecentlyPlayedUseCase: recentlyPlayedUseCase
        )
    }()

    var body: some View {
        NavigationStack(path: $router.path) {
            HomeView(viewModel: homeViewModel)
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .home:
                        HomeView(viewModel: homeViewModel)
                    case .player(let song, let playlist):
                        makePlayerView(song: song, playlist: playlist)
                    case .album(let collectionId, let collectionName, let artworkURL):
                        makeAlbumView(collectionId: collectionId, collectionName: collectionName, artworkURL: artworkURL)
                    }
                }
        }
        .environment(router)
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
        let repository = SongsRepository(networkService: networkService)
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
        .preferredColorScheme(.dark)
}
