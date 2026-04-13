import Foundation
@testable import moisesai_iphone_challenge

final class MockSaveRecentlyPlayedUseCase: SaveRecentlyPlayedUseCaseProtocol, @unchecked Sendable {
    var executeCallCount = 0
    var lastSong: Song?

    func execute(_ song: Song) async {
        executeCallCount += 1
        lastSong = song
    }
}
