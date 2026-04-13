import Foundation
@testable import moisesai_iphone_challenge

final class MockFetchAlbumSongsUseCase: FetchAlbumSongsUseCaseProtocol, @unchecked Sendable {
    var executeCallCount = 0
    var executeLastCollectionId: Int?
    var executeResult: [Song] = []
    var executeError: Error?

    func execute(collectionId: Int) async throws -> [Song] {
        executeCallCount += 1
        executeLastCollectionId = collectionId

        if let error = executeError {
            throw error
        }
        return executeResult
    }
}
