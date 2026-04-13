import SwiftUI

struct LoadingView: View {
    var message: String = Strings.loading

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

extension LoadingView {
    enum Strings {
        static let loading = NSLocalizedString("general.loading", comment: "")
    }
}

#Preview {
    LoadingView()
        .background(.black)
        .preferredColorScheme(.dark)
}
