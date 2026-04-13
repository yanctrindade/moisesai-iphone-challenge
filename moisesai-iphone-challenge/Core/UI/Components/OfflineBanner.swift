import SwiftUI

// MARK: - View

private struct OfflineBanner: View {
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
            .accessibilityElement(children: .contain)
            .accessibilityLabel(Strings.offlineMessage)
        }
    }
}

// MARK: - Modifier

private struct OfflineBannerModifier: ViewModifier {
    @Environment(NetworkMonitor.self) private var networkMonitor
    @State private var isDismissed = false

    private var showBanner: Bool {
        !networkMonitor.isConnected && !isDismissed
    }

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                OfflineBanner(isVisible: showBanner) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isDismissed = true
                    }
                }
                .padding(.bottom, Spacing.sm)
                .animation(.easeInOut(duration: 0.3), value: showBanner)
            }
            .onChange(of: networkMonitor.isConnected) { _, connected in
                if !connected {
                    isDismissed = false
                }
            }
    }
}

extension View {
    func offlineBanner() -> some View {
        modifier(OfflineBannerModifier())
    }
}

// MARK: - Strings

extension OfflineBanner {
    enum Strings {
        static let offlineMessage = NSLocalizedString("offline.banner.message", comment: "")
        static let dismiss = NSLocalizedString("general.dismiss", comment: "")
    }
}

#Preview {
    Color.black
        .ignoresSafeArea()
        .offlineBanner()
        .environment({
            let m = NetworkMonitor()
            return m
        }())
        .preferredColorScheme(.dark)
}
