import SwiftUI

struct ErrorStateView: View {
    let message: String
    var retryAction: (() -> Void)?

    var body: some View {
        ContentUnavailableView {
            Label(L10n.errorTitle, systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            if let retryAction {
                Button(L10n.tryAgain, action: retryAction)
                    .buttonStyle(.bordered)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    ErrorStateView(message: "Failed to load songs", retryAction: {})
        .preferredColorScheme(.dark)
}
