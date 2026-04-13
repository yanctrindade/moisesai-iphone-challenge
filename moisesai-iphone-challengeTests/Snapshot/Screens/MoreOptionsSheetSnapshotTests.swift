import Testing
import SwiftUI
import SnapshotTesting
@testable import moisesai_iphone_challenge

@Suite("MoreOptionsSheet Snapshot Tests")
@MainActor
struct MoreOptionsSheetSnapshotTests {

    @Test func test_moreOptionsSheet() {
        let song = SongFixture.make(
            trackName: "LOVE. (feat. Zacari)",
            artistName: "Kendrick Lamar",
            collectionName: "DAMN."
        )

        let view = MoreOptionsSheet(
            song: song,
            onViewAlbum: {}
        )
        .frame(width: 393, height: 250)
        .background(Color(hex: 0x262626, opacity: 0.8))
        .preferredColorScheme(.dark)

        let vc = UIHostingController(rootView: view)
        assertSnapshot(of: vc, as: .image(size: CGSize(width: 393, height: 250)))
    }
}
