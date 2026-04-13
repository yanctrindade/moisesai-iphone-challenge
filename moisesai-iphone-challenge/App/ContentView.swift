import SwiftUI

struct ContentView: View {
    @State private var router = Router()

    var body: some View {
        NavigationStack(path: $router.path) {
            Text("Home Placeholder")
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .home:
                        Text("Home")
                    case .player:
                        Text("Player")
                    case .album:
                        Text("Album")
                    }
                }
        }
        .preferredColorScheme(.dark)
        .environment(router)
    }
}

#Preview {
    ContentView()
}
