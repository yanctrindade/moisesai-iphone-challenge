import SwiftUI
import SwiftData

@main
struct moisesai_iphone_challengeApp: App {
    var body: some Scene {
        WindowGroup {
            SplashView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(for: [CachedSong.self, RecentlyPlayedSong.self])
    }
}
