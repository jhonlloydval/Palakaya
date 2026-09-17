import SwiftUI
import SwiftData

struct LoginView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        @Bindable var appState = appState
        ScrollView {
            VStack(spacing: 0) {
                VStack(spacing: 12) {
                    Image("PalakayaAppIcon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 64, height: 64)
                    VStack(spacing: 2) {
                        Text("PALAKAYA").font(.system(size: 22, weight: .bold)).tracking(0.6)
                        Text("Catch. Connect. Get a Fair Price.").font(.system(size: 13)).foregroundColor(.pkSub)
                    }
                }
                .padding(.bottom, 36)

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
        let mobile = appState.loginMobile
        let password = appState.loginPassword
        let descriptor = FetchDescriptor<UserAccount>(predicate: #Predicate { $0.mobile == mobile })
        guard let user = (try? modelContext.fetch(descriptor))?.first else {
            appState.loginError = "No account found for that mobile number."
            return
        }
        guard user.password == password else {
            appState.loginError = "Incorrect password."
            return
        }
        appState.loginError = nil
        appState.applyUser(user)
        appState.phase = .main
    }
}
