import Testing
import SwiftUI
import SnapshotTesting
@testable import moisesai_iphone_challenge

@Suite("AlbumView Snapshot Tests")
@MainActor
struct AlbumViewSnapshotTests {

    private let deviceSize = CGSize(width: 393, height: 852)

    @Test func test_albumView_loading() {
        let useCase = MockFetchAlbumSongsUseCase()
        let vm = AlbumViewModel(
            collectionId: 100,
            collectionName: "Random Access Memories",
            artworkURL: nil,
            fetchAlbumSongsUseCase: useCase
        )

        let view = NavigationStack {
            AlbumView(viewModel: vm)
        }
        .environment(Router())
        .preferredColorScheme(.dark)

        let vc = UIHostingController(rootView: view)
        assertSnapshot(of: vc, as: .image(size: deviceSize))
    }

    @Test func test_albumView_loaded() async throws {
        let useCase = MockFetchAlbumSongsUseCase()
        useCase.executeResult = SongFixture.makeList(count: 6)

        let vm = AlbumViewModel(
            collectionId: 100,
            collectionName: "Random Access Memories",
            artworkURL: nil,
            fetchAlbumSongsUseCase: useCase
        )

        vm.send(.onAppear)
        try await Task.sleep(for: .milliseconds(100))

        let view = NavigationStack {
            AlbumView(viewModel: vm)
        }
        .environment(Router())
        .preferredColorScheme(.dark)

        let vc = UIHostingController(rootView: view)
        assertSnapshot(of: vc, as: .image(size: deviceSize))
    }

    @Test func test_albumView_error() async throws {
        let useCase = MockFetchAlbumSongsUseCase()
        useCase.executeError = NetworkError.noConnection

        let vm = AlbumViewModel(
            collectionId: 100,
            collectionName: "Random Access Memories",
            artworkURL: nil,
            fetchAlbumSongsUseCase: useCase
        )

        vm.send(.onAppear)
        try await Task.sleep(for: .milliseconds(100))

        let view = NavigationStack {
            AlbumView(viewModel: vm)
        }
        .environment(Router())
        .preferredColorScheme(.dark)

        let vc = UIHostingController(rootView: view)
        assertSnapshot(of: vc, as: .image(size: deviceSize))
    }
}
