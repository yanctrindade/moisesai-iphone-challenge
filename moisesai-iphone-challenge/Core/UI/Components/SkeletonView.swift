import SwiftUI

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .overlay {
                if !reduceMotion {
                    LinearGradient(
                        colors: [
                            .clear,
                            Color.white.opacity(0.1),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .offset(x: phase * 200)
                    .onAppear {
                        withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                            phase = 1
                        }
                    }
                }
            }
            .clipped()
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

struct SkeletonSongRow: View {
    var body: some View {
        HStack(spacing: Spacing.md) {
            RoundedRectangle(cornerRadius: Sizing.cornerRadiusSmall)
                .fill(Color(.systemGray5))
                .frame(width: Sizing.songRowArtwork, height: Sizing.songRowArtwork)

            VStack(alignment: .leading, spacing: Spacing.sm) {
                RoundedRectangle(cornerRadius: Spacing.xs)
                    .fill(Color(.systemGray5))
                    .frame(width: 160, height: 14)

                RoundedRectangle(cornerRadius: Spacing.xs)
                    .fill(Color(.systemGray5))
                    .frame(width: 100, height: 10)
            }

            Spacer()
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.sm)
        .shimmer()
    }
}

struct SkeletonListView: View {
    let count: Int

    init(count: Int = 8) {
        self.count = count
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(0..<count, id: \.self) { _ in
                    SkeletonSongRow()
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

#Preview {
    SkeletonListView()
        .background(.black)
        .preferredColorScheme(.dark)
}
