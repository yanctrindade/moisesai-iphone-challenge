import Foundation
@testable import moisesai_iphone_challenge

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
            fatalError("MockNetworkService: resultData not set or wrong type. Expected \(T.self)")
        }

        return result
    }
}
