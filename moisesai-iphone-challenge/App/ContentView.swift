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
                    case .album:
                        Text("Album — Coming Soon")
                    }
                }
        }
        .environment(router)
    }

    private func makePlayerView(song: Song, playlist: [Song]) -> PlayerView {
        let repository = SongsRepository(networkService: networkService)
        let saveRecentlyPlayedUseCase = SaveRecentlyPlayedUseCase(repository: repository)
        let audioPlayer = AudioPlayerService()

        return PlayerView(
            viewModel: PlayerViewModel(
                song: song,
                playlist: playlist,
                audioPlayer: audioPlayer,
                saveRecentlyPlayedUseCase: saveRecentlyPlayedUseCase
            )
        )
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}
