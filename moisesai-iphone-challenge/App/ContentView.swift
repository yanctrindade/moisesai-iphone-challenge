import SwiftUI

struct ContentView: View {
    @State private var router = Router()
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
                    case .player:
                        Text("Player — Coming Soon")
                    case .album:
                        Text("Album — Coming Soon")
                    }
                }
        }
        .environment(router)
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}
