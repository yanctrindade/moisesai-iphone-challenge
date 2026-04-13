import SwiftUI

struct ErrorStateView: View {
    let message: String
    var retryAction: (() -> Void)?

    var body: some View {
        ContentUnavailableView {
            Label(NSLocalizedString("general.error.title", comment: ""), systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            if let retryAction {
                Button(NSLocalizedString("general.error.tryAgain", comment: ""), action: retryAction)
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
