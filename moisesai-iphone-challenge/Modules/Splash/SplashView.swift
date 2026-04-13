import SwiftUI
import SwiftData

struct SplashView: View {
    let deps: AppDependencies

    @State private var isActive = false
    @State private var iconOpacity: Double = 0

    var body: some View {
        if isActive {
            ContentView(deps: deps)
                .transition(.opacity)
        } else {
            splashContent
                .transition(.opacity)
        }
    }

    private var splashContent: some View {
        ZStack {
            // Matches Figma: linear-gradient(39.45deg, #000000 33.57%, #0086A0 205.11%)
            // CSS 0deg = up; 39.45deg points toward upper-right.
            // So gradient line runs from bottom-left (0%) to upper-right (100%+).
            // Black dominates from bottom-left through 33.57%; teal sits at 205% (way off-canvas),
            // producing only a subtle teal bloom in the top-right corner.
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: AppColors.splashGradientStart, location: 0.0),
                    .init(color: AppColors.splashGradientStart, location: 0.3357),
                    .init(color: AppColors.splashGradientEnd, location: 2.0511)
                ]),
                startPoint: .bottomLeading,
                endPoint: .topTrailing
            )
            .ignoresSafeArea()

            Image("SplashIcon")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: Sizing.splashIcon, height: Sizing.splashIcon)
                .opacity(iconOpacity)
                .accessibilityHidden(true)
        }
        .task {
            withAnimation(.easeIn(duration: Timing.splashFadeIn)) {
                iconOpacity = 1
            }

            try? await Task.sleep(for: .seconds(Timing.splashFadeIn + Timing.splashHold))

            guard !Task.isCancelled else { return }

            withAnimation(.easeInOut(duration: Timing.splashFadeOut)) {
                isActive = true
            }
        }
    }
}

#Preview {
    let container = try! ModelContainer(
        for: CachedSong.self, RecentlyPlayedSong.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let monitor = NetworkMonitor()
    let deps = AppDependencies.live(modelContainer: container, networkMonitor: monitor)

    SplashView(deps: deps)
        .environment(monitor)
        .preferredColorScheme(.dark)
}
