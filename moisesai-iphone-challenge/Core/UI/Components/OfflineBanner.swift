import SwiftUI

struct OfflineBanner: View {
    let isVisible: Bool

    var body: some View {
        if isVisible {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "wifi.slash")
                    .font(.caption)
                    .foregroundStyle(.white)

                Text(Strings.offlineMessage)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.sm)
            .padding(.horizontal, Spacing.lg)
            .background(Color(.systemGray).opacity(0.3))
            .background(.ultraThinMaterial)
            .transition(.move(edge: .top).combined(with: .opacity))
            .accessibilityElement(children: .combine)
            .accessibilityLabel(Strings.offlineMessage)
        }
    }
}

extension OfflineBanner {
    enum Strings {
        static let offlineMessage = NSLocalizedString("offline.banner.message", comment: "")
    }
}

#Preview {
    VStack {
        OfflineBanner(isVisible: true)
        Spacer()
    }
    .background(.black)
    .preferredColorScheme(.dark)
}
