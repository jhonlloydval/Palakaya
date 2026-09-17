import SwiftUI

struct RootView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Group {
            switch appState.phase {
            case .onboarding: OnboardingView()
            case .login: LoginView()
            case .register: RegisterView()
            case .main: MainTabView()
            }
        }
        .animation(.easeInOut(duration: 0.2), value: appState.phase)
    }
}
