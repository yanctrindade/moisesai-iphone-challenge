import Foundation
import Network
import os

private let logger = Logger(subsystem: "com.yantrindade.moisesai", category: "NetworkMonitor")

@Observable
@MainActor
final class NetworkMonitor: NetworkMonitorProtocol {
    private(set) var isConnected: Bool = true

    private let monitor: NWPathMonitor
    private let queue: DispatchQueue
    private var isStarted = false

    init() {
        self.monitor = NWPathMonitor()
        self.queue = DispatchQueue(label: "com.yantrindade.moisesai.networkmonitor")
    }

    func start() {
        guard !isStarted else { return }
        isStarted = true

        monitor.pathUpdateHandler = { [weak self] path in
            let connected = path.status == .satisfied
            Task { @MainActor in
                guard let self else { return }
                if self.isConnected != connected {
                    logger.info("Network status changed: \(connected ? "connected" : "disconnected")")
                    self.isConnected = connected
                }
            }
        }

        monitor.start(queue: queue)
    }

    func stop() {
        monitor.cancel()
        isStarted = false
    }

    deinit {
        monitor.cancel()
    }
}
