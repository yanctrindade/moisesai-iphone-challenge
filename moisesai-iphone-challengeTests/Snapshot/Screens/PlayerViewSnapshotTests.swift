import Testing
import SwiftUI
import SnapshotTesting
@testable import moisesai_iphone_challenge

@Suite("PlayerView Snapshot Tests")
@MainActor
struct PlayerViewSnapshotTests {

    private let deviceSize = CGSize(width: 393, height: 852)

    private func makeViewModel() -> PlayerViewModel {
        let audioPlayer = MockAudioPlayerService()
        let saveUseCase = MockSaveRecentlyPlayedUseCase()
        let song = SongFixture.make(
            trackName: "Get Lucky",
            artistName: "Daft Punk feat. Pharrell Williams",
            collectionName: "Random Access Memories"
        )

        return PlayerViewModel(
            song: song,
            playlist: [song],
            audioPlayer: audioPlayer,
            saveRecentlyPlayedUseCase: saveUseCase
        )
    }

    @Test func test_playerView_idle() {
        let vm = makeViewModel()
        let view = NavigationStack {
            PlayerView(viewModel: vm)
        }
        .environment(Router())
        .preferredColorScheme(.dark)

        let vc = UIHostingController(rootView: view)
        assertSnapshot(of: vc, as: .image(size: deviceSize))
    }

    @Test func test_playerView_playing() async throws {
        let vm = makeViewModel()
        vm.send(.onAppear)
        try await Task.sleep(for: .milliseconds(100))

        let view = NavigationStack {
            PlayerView(viewModel: vm)
        }
        .environment(Router())
        .preferredColorScheme(.dark)

        let vc = UIHostingController(rootView: view)
        assertSnapshot(of: vc, as: .image(size: deviceSize))
    }
}
