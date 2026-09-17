import SwiftUI

/// Branded screen shown for a moment after launch, continuing the static launch screen.
struct SplashView: View {
    @State private var showName = false

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(spacing: 20) {
                Image("LaunchLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 140)
                Text("Gymbro")
                    .font(Theme.display(44))
                    .foregroundStyle(Theme.textPrimary)
                    .opacity(showName ? 1 : 0)
                    .offset(y: showName ? 0 : 8)
            }
            // Keep the logo where the launch storyboard draws it (screen center) and
            // let the name appear below it.
            .offset(y: 32)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.35).delay(0.1)) { showName = true }
        }
    }
}

#Preview {
    SplashView()
}
