import Testing
import SwiftUI
import SnapshotTesting
@testable import moisesai_iphone_challenge

@Suite("LoadingView Snapshot Tests")
@MainActor
struct LoadingViewSnapshotTests {

    @Test func test_loadingView() {
        let view = LoadingView()
            .frame(width: 393, height: 300)
            .background(.black)
            .preferredColorScheme(.dark)

        let vc = UIHostingController(rootView: view)
        assertSnapshot(of: vc, as: .image(size: CGSize(width: 393, height: 300)))
    }
}
