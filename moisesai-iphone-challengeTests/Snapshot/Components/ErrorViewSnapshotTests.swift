import Testing
import SwiftUI
import SnapshotTesting
@testable import moisesai_iphone_challenge

@Suite("ErrorStateView Snapshot Tests")
@MainActor
struct ErrorViewSnapshotTests {

    @Test func test_errorView_withRetry() {
        let view = ErrorStateView(message: "No internet connection") {}
            .frame(width: 393, height: 300)
            .background(.black)
            .preferredColorScheme(.dark)

        let vc = UIHostingController(rootView: view)
        assertSnapshot(of: vc, as: .image(size: CGSize(width: 393, height: 300)))
    }

    @Test func test_errorView_withoutRetry() {
        let view = ErrorStateView(message: "Something went wrong")
            .frame(width: 393, height: 300)
            .background(.black)
            .preferredColorScheme(.dark)

        let vc = UIHostingController(rootView: view)
        assertSnapshot(of: vc, as: .image(size: CGSize(width: 393, height: 300)))
    }
}
