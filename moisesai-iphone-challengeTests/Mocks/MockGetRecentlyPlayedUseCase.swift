import Foundation
@testable import moisesai_iphone_challenge

final class MockGetRecentlyPlayedUseCase: GetRecentlyPlayedUseCaseProtocol, @unchecked Sendable {
    var executeCallCount = 0
    var executeResult: [Song] = []

    func execute() async -> [Song] {
        executeCallCount += 1
        return executeResult
    }
}
