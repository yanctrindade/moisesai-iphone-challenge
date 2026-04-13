import SwiftUI

@MainActor
protocol RouterProtocol: AnyObject, Observable {
    var path: NavigationPath { get set }
    func push(_ route: Route)
    func pop()
    func popToRoot()
}

@Observable
@MainActor
final class Router: RouterProtocol {
    var path = NavigationPath()

    func push(_ route: Route) {
        path.append(route)
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func popToRoot() {
        path = NavigationPath()
    }
}
