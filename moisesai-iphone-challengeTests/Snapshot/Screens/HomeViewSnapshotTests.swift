import Testing
import SwiftUI
import SnapshotTesting
@testable import moisesai_iphone_challenge

@Suite("HomeView Snapshot Tests")
@MainActor
struct HomeViewSnapshotTests {

    private let deviceSize = CGSize(width: 393, height: 852) // iPhone 17 Pro

    private func makeViewModel(
        state: HomeViewModel.ViewState = .idle,
        recentlyPlayed: [Song] = []
    ) -> HomeViewModel {
        let searchUseCase = MockSearchSongsUseCase()
        let recentlyPlayedUseCase = MockGetRecentlyPlayedUseCase()
        recentlyPlayedUseCase.executeResult = recentlyPlayed

        let vm = HomeViewModel(
            searchSongsUseCase: searchUseCase,
            getRecentlyPlayedUseCase: recentlyPlayedUseCase
        )
        return vm
    }

    @Test func test_homeView_emptyState() {
        let vm = makeViewModel()
        let view = NavigationStack {
            HomeView(viewModel: vm)
        }
        .environment(Router())
        .preferredColorScheme(.dark)

        let vc = UIHostingController(rootView: view)
        assertSnapshot(of: vc, as: .image(size: deviceSize))
    }

    @Test func test_homeView_withRecentlyPlayed() async throws {
        let songs = SongFixture.makeList(count: 3)
        let vm = makeViewModel(recentlyPlayed: songs)

        vm.send(.onAppear)
        try await Task.sleep(for: .milliseconds(100))

        let view = NavigationStack {
            HomeView(viewModel: vm)
        }
        .environment(Router())
        .preferredColorScheme(.dark)

        let vc = UIHostingController(rootView: view)
        assertSnapshot(of: vc, as: .image(size: deviceSize))
    }
}
