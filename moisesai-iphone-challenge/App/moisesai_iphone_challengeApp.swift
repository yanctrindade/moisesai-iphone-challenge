import SwiftUI
import SwiftData

@main
struct moisesai_iphone_challengeApp: App {
    @State private var networkMonitor: NetworkMonitor = {
        let monitor = NetworkMonitor()
        monitor.start()
        return monitor
    }()

    private let modelContainer: ModelContainer = {
        do {
            return try ModelContainer(for: CachedSong.self, RecentlyPlayedSong.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            SplashView(deps: makeDependencies())
                .preferredColorScheme(.dark)
                .environment(networkMonitor)
        }
        .modelContainer(modelContainer)
    }

    private func makeDependencies() -> AppDependencies {
        AppDependencies.live(modelContainer: modelContainer, networkMonitor: networkMonitor)
    }
}
