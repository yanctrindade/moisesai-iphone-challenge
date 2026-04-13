import SwiftUI

struct MarqueeText: View {
    let text: String
    let font: Font
    let color: Color
    let maxWidth: CGFloat
    let uiFont: UIFont

    @State private var offset: CGFloat = 0

    private let spacing: CGFloat = 40
    private let speed: Double = 30

    init(
        text: String,
        font: Font,
        color: Color,
        maxWidth: CGFloat,
        uiFont: UIFont = UIFont.systemFont(ofSize: 16, weight: .semibold)
    ) {
        self.text = text
        self.font = font
        self.color = color
        self.maxWidth = maxWidth
        self.uiFont = uiFont
    }

    private var textWidth: CGFloat {
        let attributes: [NSAttributedString.Key: Any] = [.font: uiFont]
        return (text as NSString).size(withAttributes: attributes).width
    }

    var body: some View {
        if maxWidth.isFinite {
            // Simple path when a concrete maxWidth was provided (e.g., toolbar title).
            // GeometryReader inside a toolbar doesn't always report a usable size,
            // so we compare directly against the given maxWidth.
            fixedWidthBody
        } else {
            // Dynamic container width (e.g., full-width player song title).
            geometryWidthBody
        }
    }

    @ViewBuilder
    private var fixedWidthBody: some View {
        let shouldScroll = textWidth > maxWidth
        if shouldScroll {
            scrollingContent(width: maxWidth)
        } else {
            Text(text)
                .font(font)
                .foregroundStyle(color)
                .lineLimit(1)
        }
    }

    private var geometryWidthBody: some View {
        GeometryReader { geo in
            let available = geo.size.width
            let shouldScroll = textWidth > available

            Group {
                if shouldScroll {
                    scrollingContent(width: available)
                } else {
                    Text(text)
                        .font(font)
                        .foregroundStyle(color)
                        .lineLimit(1)
                }
            }
            // Hide until GeometryReader has measured to avoid a flash
            // while containerWidth transitions from 0 to the real value.
            .opacity(available > 0 ? 1 : 0)
        }
    }

    private func scrollingContent(width: CGFloat) -> some View {
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
        .frame(width: width, alignment: .leading)
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
