import SwiftUI

struct MarqueeText: View {
    let text: String
    let font: Font
    let color: Color
    let maxWidth: CGFloat

    @State private var offset: CGFloat = 0
    @State private var needsScroll = false

    private let spacing: CGFloat = 40
    private let speed: Double = 30

    private var textWidth: CGFloat {
        let uiFont = UIFont.systemFont(ofSize: 16, weight: .semibold)
        let attributes: [NSAttributedString.Key: Any] = [.font: uiFont]
        return (text as NSString).size(withAttributes: attributes).width
    }

    var body: some View {
        let shouldScroll = textWidth > maxWidth

        Group {
            if shouldScroll {
                scrollingContent
            } else {
                Text(text)
                    .font(font)
                    .foregroundStyle(color)
                    .lineLimit(1)
            }
        }
    }

    private var scrollingContent: some View {
        let totalWidth = textWidth + spacing

        return HStack(spacing: spacing) {
            Text(text)
                .font(font)
                .foregroundStyle(color)
                .fixedSize()

            Text(text)
                .font(font)
                .foregroundStyle(color)
                .fixedSize()
        }
        .offset(x: offset)
        .frame(width: maxWidth, alignment: .leading)
        .clipped()
        .onAppear {
            startAnimation(totalWidth: totalWidth)
        }
        .onChange(of: text) {
            offset = 0
            let newTotal = textWidth + spacing
            startAnimation(totalWidth: newTotal)
        }
    }

    private func startAnimation(totalWidth: CGFloat) {
        offset = 0
        let duration = totalWidth / speed

        withAnimation(
            .linear(duration: duration)
            .repeatForever(autoreverses: false)
            .delay(1.5)
        ) {
            offset = -totalWidth
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        MarqueeText(
            text: "Short",
            font: .system(size: 16, weight: .semibold),
            color: .white,
            maxWidth: 200
        )

        MarqueeText(
            text: "This Is A Very Long Album Title That Should Scroll",
            font: .system(size: 16, weight: .semibold),
            color: .white,
            maxWidth: 200
        )
    }
    .padding()
    .background(.black)
    .preferredColorScheme(.dark)
}
