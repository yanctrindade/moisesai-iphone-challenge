import Foundation
@testable import moisesai_iphone_challenge

@Observable
@MainActor
final class MockNetworkMonitor: NetworkMonitorProtocol {
    var isConnected: Bool = true
    var startCallCount = 0
    var stopCallCount = 0

    func start() {
        startCallCount += 1
    }

    func stop() {
        stopCallCount += 1
    }
}
