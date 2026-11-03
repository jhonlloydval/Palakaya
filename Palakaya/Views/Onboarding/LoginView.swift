import SwiftUI
import SwiftData

struct LoginView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @State private var isLoggingIn = false
    @State private var showForgot = false

    var body: some View {
        @Bindable var appState = appState
        ScrollView {
            VStack(spacing: 0) {
                Image("PalakayaLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200)
                    .accessibilityLabel("Palakaya. Catch. Connect. Get a Fair Price.")
                    .padding(.bottom, 28)

                PKTextField(placeholder: "09XX XXX XXXX", text: $appState.loginMobile, keyboard: .phonePad)
                    .pkField("Mobile Number")
                PKTextField(text: $appState.loginPassword, isSecure: true)
                    .pkField("Password")

                if let error = appState.loginError {
                    Text(error).font(.system(size: 12.5)).foregroundColor(.pkDanger)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 8)
                }

                HStack {
                    Spacer()
                    Button("Forgot Password?") { showForgot = true }
                        .font(.system(size: 13, weight: .medium)).foregroundColor(.pkDark)
                }
                .padding(.bottom, 22)

                GradientButton(title: isLoggingIn ? "Logging in…" : "Log In") { doLogin() }

                HStack(spacing: 5) {
                    Text("Don't have an account?").foregroundColor(.pkSub)
                    Button("Create Account") { appState.phase = .register }
                        .fontWeight(.semibold).foregroundColor(.pkDark)
                }
                .font(.system(size: 13))
                .padding(.top, 22)
            }
            .padding(.horizontal, 24)
            .padding(.top, 72)
        }
        .background(Color.pkBg)
        .scrollDismissesKeyboard(.interactively)
        .alert("Forgot your password?", isPresented: $showForgot) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Resetting by text message is coming soon. For now, ask the Palakaya team to reset it, using the mobile number you signed up with. If you're still logged in on another phone, you can change it there in Profile → Personal Information.")
        }
    }

    private func doLogin() {
        guard !isLoggingIn else { return }
        isLoggingIn = true
        Task {
            defer { isLoggingIn = false }
            do {
                let user = try await AuthController(context: modelContext)
                    .login(mobile: appState.loginMobile, password: appState.loginPassword)
                appState.loginError = nil
                appState.applyUser(user)
                appState.phase = .main
                let password = appState.loginPassword
                appState.loginPassword = ""
                await SyncController.connectAndSync(user: user, password: password, appState: appState, context: modelContext)
            } catch {
                appState.loginError = error.localizedDescription
            }
        }
    }
}
