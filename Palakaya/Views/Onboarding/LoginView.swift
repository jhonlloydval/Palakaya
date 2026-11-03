import SwiftUI
import SwiftData

struct LoginView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

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
                    Button("Forgot Password?") {}
                        .font(.system(size: 13, weight: .medium)).foregroundColor(.pkDark)
                }
                .padding(.bottom, 22)

                GradientButton(title: "Log In") { doLogin() }

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
    }

    private func doLogin() {
        do {
            let user = try AuthController(context: modelContext)
                .login(mobile: appState.loginMobile, password: appState.loginPassword)
            appState.loginError = nil
            appState.applyUser(user)
            appState.phase = .main
            let password = appState.loginPassword
            appState.loginPassword = ""
            Task { await SyncController.connectAndSync(user: user, password: password, appState: appState, context: modelContext) }
        } catch {
            appState.loginError = error.localizedDescription
        }
    }
}
