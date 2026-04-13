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
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: AppColors.splashGradientStart, location: 0.0),
                    .init(color: AppColors.splashGradientStart, location: 0.5),
                    .init(color: AppColors.splashGradientEnd, location: 1.0)
                ]),
                startPoint: UnitPoint(x: 0.18, y: 0.0),
                endPoint: UnitPoint(x: 0.82, y: 1.0)
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
