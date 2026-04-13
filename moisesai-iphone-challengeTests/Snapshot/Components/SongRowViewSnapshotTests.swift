import Testing
import SwiftUI
import SnapshotTesting
@testable import moisesai_iphone_challenge

@Suite("SongRowView Snapshot Tests")
@MainActor
struct SongRowViewSnapshotTests {

    private func makeView(showMoreButton: Bool = true) -> some View {
        SongRowView(
            song: SongFixture.make(
                trackName: "Purple Rain",
                artistName: "Prince"
            ),
            showMoreButton: showMoreButton
        )
        .padding(.horizontal, 16)
        .frame(width: 393)
        .background(.black)
        .preferredColorScheme(.dark)
    }

    @Test func test_songRow_withMoreButton() {
        let view = makeView(showMoreButton: true)
        let vc = UIHostingController(rootView: view)
        vc.view.frame = CGRect(x: 0, y: 0, width: 393, height: 70)

        assertSnapshot(of: vc, as: .image(size: CGSize(width: 393, height: 70)))
    }

    @Test func test_songRow_withoutMoreButton() {
        let view = makeView(showMoreButton: false)
        let vc = UIHostingController(rootView: view)
        vc.view.frame = CGRect(x: 0, y: 0, width: 393, height: 70)

        assertSnapshot(of: vc, as: .image(size: CGSize(width: 393, height: 70)))
    }
}
