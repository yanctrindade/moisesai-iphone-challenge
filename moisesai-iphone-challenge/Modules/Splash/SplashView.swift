import SwiftUI

struct SplashView: View {
    private enum Constants {
        static let iconSize: CGFloat = 100
        static let fadeInDuration: Double = 0.5
        static let holdDuration: Double = 2.0
        static let fadeOutDuration: Double = 0.4
    }

    @State private var isActive = false
    @State private var iconOpacity: Double = 0

    var body: some View {
        if isActive {
            ContentView()
                .transition(.opacity)
        } else {
            splashContent
                .transition(.opacity)
        }
    }

    private var splashContent: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color(hex: 0x000000), location: 0.0),
                    .init(color: Color(hex: 0x000000), location: 0.8),
                    .init(color: Color(hex: 0x0086A0), location: 1.0)
                ]),
                startPoint: UnitPoint(x: 0.18, y: 0.0),
                endPoint: UnitPoint(x: 0.82, y: 1.0)
            )
            .ignoresSafeArea()

            Image("SplashIcon")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: Constants.iconSize, height: Constants.iconSize)
                .opacity(iconOpacity)
                .accessibilityHidden(true)
        }
        .task {
            withAnimation(.easeIn(duration: Constants.fadeInDuration)) {
                iconOpacity = 1
            }

            try? await Task.sleep(for: .seconds(Constants.fadeInDuration + Constants.holdDuration))

            guard !Task.isCancelled else { return }

            withAnimation(.easeInOut(duration: Constants.fadeOutDuration)) {
                isActive = true
            }
        }
    }
}

#Preview {
    SplashView()
        .preferredColorScheme(.dark)
}
