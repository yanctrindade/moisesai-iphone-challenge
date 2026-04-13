import SwiftUI

struct ErrorStateView: View {
    let message: String
    var retryAction: (() -> Void)?

    var body: some View {
        ContentUnavailableView {
            Label(Strings.errorTitle, systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            if let retryAction {
                Button(Strings.tryAgain, action: retryAction)
                    .buttonStyle(.bordered)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

extension ErrorStateView {
    enum Strings {
        static let errorTitle = NSLocalizedString("general.error.title", comment: "")
        static let tryAgain = NSLocalizedString("general.error.tryAgain", comment: "")
    }
}

#Preview {
    ErrorStateView(message: "Failed to load songs", retryAction: {})
        .preferredColorScheme(.dark)
}
