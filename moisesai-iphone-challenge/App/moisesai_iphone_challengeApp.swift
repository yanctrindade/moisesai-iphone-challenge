import SwiftUI
import SwiftData

@main
struct moisesai_iphone_challengeApp: App {
    @State private var networkMonitor: NetworkMonitor = {
        let monitor = NetworkMonitor()
        monitor.start()
        return monitor
    }()

    var body: some Scene {
        WindowGroup {
            SplashView()
                .preferredColorScheme(.dark)
                .environment(networkMonitor)
        }
        .modelContainer(for: [CachedSong.self, RecentlyPlayedSong.self])
    }
}
