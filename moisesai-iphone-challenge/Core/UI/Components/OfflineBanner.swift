import SwiftUI

struct OfflineBanner: View {
    let isVisible: Bool
    var onDismiss: (() -> Void)?

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

                Spacer()

                if let onDismiss {
                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                            .frame(width: 32, height: 32)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Strings.dismiss)
                }
            }
            .padding(.vertical, Spacing.sm)
            .padding(.horizontal, Spacing.lg)
            .background(Color(.systemGray6).opacity(0.9))
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
        static let dismiss = NSLocalizedString("general.dismiss", comment: "")
    }
}

#Preview {
    VStack {
        OfflineBanner(isVisible: true, onDismiss: {})
        Spacer()
    }
    .background(.black)
    .preferredColorScheme(.dark)
}
