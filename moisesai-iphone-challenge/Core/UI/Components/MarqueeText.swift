import SwiftUI

struct MarqueeText: View {
    let text: String
    let font: Font
    let color: Color
    let maxWidth: CGFloat

    @State private var textWidth: CGFloat = 0
    @State private var offset: CGFloat = 0
    @State private var animating = false

    private let spacing: CGFloat = 40
    private let speed: Double = 30 // points per second

    var body: some View {
        GeometryReader { geo in
            let containerWidth = geo.size.width
            let shouldScroll = textWidth > containerWidth

            if shouldScroll {
                scrollingContent(containerWidth: containerWidth)
            } else {
                staticContent
            }
        }
        .frame(maxWidth: maxWidth)
        .frame(height: 20)
        .clipped()
    }

    private var staticContent: some View {
        Text(text)
            .font(font)
            .foregroundStyle(color)
            .lineLimit(1)
            .frame(maxWidth: .infinity)
    }

    private func scrollingContent(containerWidth: CGFloat) -> some View {
        let totalWidth = textWidth + spacing

        return HStack(spacing: spacing) {
            Text(text)
                .font(font)
                .foregroundStyle(color)
                .lineLimit(1)
                .fixedSize()

            Text(text)
                .font(font)
                .foregroundStyle(color)
                .lineLimit(1)
                .fixedSize()
        }
        .offset(x: offset)
        .onAppear {
            textWidth = measureText(text, font: font)
            startAnimation(totalWidth: totalWidth)
        }
        .onChange(of: text) {
            offset = 0
            textWidth = measureText(text, font: font)
            let newTotalWidth = textWidth + spacing
            startAnimation(totalWidth: newTotalWidth)
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

    private func measureText(_ text: String, font: Font) -> CGFloat {
        let uiFont = UIFont.systemFont(ofSize: 16, weight: .semibold)
        let attributes: [NSAttributedString.Key: Any] = [.font: uiFont]
        let size = (text as NSString).size(withAttributes: attributes)
        return size.width
    }
}

#Preview {
    VStack(spacing: 20) {
        MarqueeText(
            text: "Short Title",
            font: .system(size: 16, weight: .semibold),
            color: .white,
            maxWidth: 200
        )

        MarqueeText(
            text: "This Is A Very Long Album Title That Should Scroll Horizontally",
            font: .system(size: 16, weight: .semibold),
            color: .white,
            maxWidth: 200
        )
    }
    .padding()
    .background(.black)
    .preferredColorScheme(.dark)
}
