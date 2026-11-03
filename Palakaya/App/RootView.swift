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
        .alert("Something went wrong", isPresented: Binding(
            get: { appState.errorMessage != nil },
            set: { if !$0 { appState.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(appState.errorMessage ?? "")
        }
    }
}
