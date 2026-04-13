import SwiftUI

struct SplashView: View {
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
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Image("SplashIcon")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .opacity(iconOpacity)
                .accessibilityHidden(true)
        }
        .onAppear {
            withAnimation(.easeIn(duration: 0.5)) {
                iconOpacity = 1
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation(.easeInOut(duration: 0.4)) {
                    isActive = true
                }
            }
        }
    }
}

#Preview {
    SplashView()
}
