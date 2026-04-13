import Foundation
@testable import moisesai_iphone_challenge

enum MockError: Error {
    case missingResultData
}

final class MockNetworkService: NetworkServiceProtocol, @unchecked Sendable {
    var requestCallCount = 0
    var lastEndpoint: Endpoint?
    var resultData: Any?
    var error: Error?

    func request<T: Decodable & Sendable>(_ endpoint: Endpoint) async throws -> T {
        requestCallCount += 1
        lastEndpoint = endpoint

        if let error {
            throw error
        }

        guard let result = resultData as? T else {
            throw MockError.missingResultData
        }

        return result
    }
}
