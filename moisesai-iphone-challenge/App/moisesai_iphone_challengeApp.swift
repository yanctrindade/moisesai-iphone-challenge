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
            let container = try ModelContainer(for: CachedSong.self, RecentlyPlayedSong.self)
            // Warm up SwiftData off the main thread so the first fetch on Home
            // doesn't pay the cold-start cost (schema setup, store file open).
            Task.detached(priority: .utility) {
                let context = ModelContext(container)
                var descriptor = FetchDescriptor<RecentlyPlayedSong>()
                descriptor.fetchLimit = 1
                _ = try? context.fetch(descriptor)
            }
            return container
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
