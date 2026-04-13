import SwiftUI
@testable import moisesai_iphone_challenge

@Observable
@MainActor
final class MockRouter: RouterProtocol {
    var path = NavigationPath()
    var pushCallCount = 0
    var lastPushedRoute: Route?
    var popCallCount = 0
    var popToRootCallCount = 0

    func push(_ route: Route) {
        pushCallCount += 1
        lastPushedRoute = route
        path.append(route)
    }

    func pop() {
        popCallCount += 1
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func popToRoot() {
        popToRootCallCount += 1
        path = NavigationPath()
    }
}
