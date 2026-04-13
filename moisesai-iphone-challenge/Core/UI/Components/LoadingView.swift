import SwiftUI

struct LoadingView: View {
    var message: String = NSLocalizedString("general.loading", comment: "")

    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .controlSize(.large)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message)
    }
}

#Preview {
    LoadingView()
        .background(.black)
        .preferredColorScheme(.dark)
}
