import Foundation
@testable import moisesai_iphone_challenge

final class MockSearchSongsUseCase: SearchSongsUseCaseProtocol, @unchecked Sendable {
    var executeCallCount = 0
    var executeLastTerm: String?
    var executeLastLimit: Int?
    var executeLastOffset: Int?
    var executeResult: [Song] = []
    var executeError: Error?

    var cachedResultsCallCount = 0
    var cachedResultsResult: [Song] = []

    func execute(term: String, limit: Int, offset: Int) async throws -> [Song] {
        executeCallCount += 1
        executeLastTerm = term
        executeLastLimit = limit
        executeLastOffset = offset

        if let error = executeError {
            throw error
        }
        return executeResult
    }

    func cachedResults(for term: String) async -> [Song] {
        cachedResultsCallCount += 1
        return cachedResultsResult
    }
}
