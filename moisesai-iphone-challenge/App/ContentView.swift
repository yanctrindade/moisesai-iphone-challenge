import SwiftUI

struct ContentView: View {
    @State private var router = Router()

    private let networkService = URLSessionNetworkService()

    var body: some View {
        NavigationStack(path: $router.path) {
            makeHomeView()
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .home:
                        makeHomeView()
                    case .player:
                        Text("Player — Coming Soon")
                    case .album:
                        Text("Album — Coming Soon")
                    }
                }
        }
        .environment(router)
    }

    private func makeHomeView() -> HomeView {
        let repository = SongsRepository(networkService: networkService)
        let searchUseCase = SearchSongsUseCase(repository: repository)
        let recentlyPlayedUseCase = GetRecentlyPlayedUseCase(repository: repository)

        return HomeView(
            viewModel: HomeViewModel(
                searchSongsUseCase: searchUseCase,
                getRecentlyPlayedUseCase: recentlyPlayedUseCase
            )
        )
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}
