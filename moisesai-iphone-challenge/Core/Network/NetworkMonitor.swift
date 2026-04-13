import Foundation
import Network
import os

private let logger = Logger(subsystem: "com.yantrindade.moisesai", category: "NetworkMonitor")

@Observable
@MainActor
final class NetworkMonitor: NetworkMonitorProtocol {
    /// Debug-only override: set to `true` to simulate offline state.
    /// Toggle via UserDefaults key "debug.forceOffline" or set `forceOffline` directly in debug builds.
    var forceOffline: Bool = false

    private var realIsConnected: Bool = true

    var isConnected: Bool {
        #if DEBUG
        if forceOffline { return false }
        #endif
        return realIsConnected
    }

    private let monitor: NWPathMonitor
    private let queue: DispatchQueue
    private var isStarted = false

    init() {
        self.monitor = NWPathMonitor()
        self.queue = DispatchQueue(label: "com.yantrindade.moisesai.networkmonitor")
        #if DEBUG
        self.forceOffline = UserDefaults.standard.bool(forKey: "debug.forceOffline")
        #endif
    }

    func start() {
        guard !isStarted else { return }
        isStarted = true

        monitor.pathUpdateHandler = { [weak self] path in
            let connected = path.status == .satisfied
            Task { @MainActor in
                guard let self else { return }
                if self.realIsConnected != connected {
                    logger.info("Network status changed: \(connected ? "connected" : "disconnected")")
                    self.realIsConnected = connected
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
