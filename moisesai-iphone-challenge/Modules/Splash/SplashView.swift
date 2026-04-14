import SwiftUI
import SwiftData

struct SplashView: View {
    let deps: AppDependencies

    @State private var isActive = false
    @State private var iconOpacity: Double = 0
    @State private var homeViewModel: HomeViewModel

    init(deps: AppDependencies) {
        self.deps = deps
        let repository = deps.songsRepository
        _homeViewModel = State(initialValue: HomeViewModel(
            searchSongsUseCase: SearchSongsUseCase(repository: repository),
            getRecentlyPlayedUseCase: GetRecentlyPlayedUseCase(repository: repository)
        ))
    }

    var body: some View {
        if isActive {
            ContentView(deps: deps, homeViewModel: homeViewModel)
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
            // Derive UnitPoints from the exact angle (not .bottomLeading/.topTrailing,
            // which would be a fixed 45°).
            //   startPoint = (0.5 - sinθ/2, 0.5 + cosθ/2)  // bottom-left area
            //   endPoint   = (0.5 + sinθ/2, 0.5 - cosθ/2)  // top-right area
            // For θ = 39.45° that gives approximately (0.182, 0.886) → (0.818, 0.114).
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: AppColors.splashGradientStart, location: 0.0),
                    .init(color: AppColors.splashGradientStart, location: 0.3357),
                    .init(color: AppColors.splashGradientEnd, location: 2.0511)
                ]),
                startPoint: UnitPoint(x: 0.182, y: 0.886),
                endPoint: UnitPoint(x: 0.818, y: 0.114)
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

            // Wait in parallel for: (a) the brand-moment animation to complete,
            // and (b) Home's initial data load + SwiftData warmup to finish.
            // Splash dismisses only when BOTH are done, so the user never lands
            // on an unresponsive Home screen. If preload is slow, we hold splash
            // (showing the animated icon) instead of freezing the user on Home.
            async let brandMoment: Void = Task.sleep(for: .seconds(Timing.splashFadeIn + Timing.splashHold))
            async let ready: Void = homeViewModel.preload()
            _ = try? await brandMoment
            await ready

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
