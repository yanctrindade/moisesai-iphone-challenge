import Foundation

@MainActor
protocol NetworkMonitorProtocol: AnyObject, Observable {
    var isConnected: Bool { get }
    func start()
    func stop()
}
