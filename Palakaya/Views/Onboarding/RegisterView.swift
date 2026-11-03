import SwiftUI
import SwiftData

struct RegisterView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        @Bindable var appState = appState
        VStack(spacing: 0) {
            HStack {
                Button { appState.phase = .login } label: {
                    Image(systemName: "chevron.left").font(.system(size: 18, weight: .semibold)).foregroundColor(.pkText)
                }
                .frame(width: 36, height: 36)
                Spacer()
                Text("Create Account").font(.system(size: 16, weight: .semibold))
                Spacer()
                Color.clear.frame(width: 36, height: 36)
            }
            .padding(.horizontal, 12)
            .frame(height: 48)

            ScrollView {
                VStack(spacing: 0) {
                    Picker("I am a", selection: $appState.regRole) {
                        Text("Fisher").tag("fisher")
                        Text("Buyer").tag("buyer")
                    }
                    .pickerStyle(.segmented)
                    .pkField("I am a")

                    if appState.regRole == "buyer" {
                        PKTextField(placeholder: "e.g. Liza's Seafood Stall", text: $appState.regBusiness)
                            .pkField("Store, Stall or Cooperative Name")
                    }
                    PKTextField(placeholder: "Juan Dela Cruz", text: $appState.regName).pkField("Full Name")
                    PKTextField(placeholder: "09XX XXX XXXX", text: $appState.regMobile, keyboard: .phonePad).pkField("Mobile Number")
                    PKTextField(placeholder: "Lucena City", text: $appState.regMunicipality).pkField("Municipality")
                    PKTextField(placeholder: "Quezon, CALABARZON", text: $appState.regProvince).pkField("Province / Region")
                    if appState.regRole == "fisher" {
                        PKTextField(placeholder: "Dalahican Landing Site", text: $appState.regLanding).pkField("Home Port / Landing Site")
                        PKTextField(placeholder: "Optional", text: $appState.regFID).pkField("Fisherfolk ID (if applicable)")
                    }
                    PKTextField(placeholder: "e.g. Kahitano1Jl", text: $appState.regPassword, isSecure: true)
                        .pkField("Password")
                        .padding(.bottom, -8)
                    passwordChecklist
                        .padding(.bottom, 18)

                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "lock.fill").foregroundColor(.pkDark)
                        Text(appState.regRole == "buyer"
                             ? "Buyers get a Verified badge after Palakaya checks their business permit or ID."
                             : "Your personal catch records stay private. Government reports use anonymized regional data.")
                            .font(.system(size: 12.5)).foregroundColor(.pkText).lineSpacing(3)
                    }
                    .padding(14)
                    .background(Color.pkSurface2)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.bottom, 22)

                    if let error = appState.registerError {
                        Text(error).font(.system(size: 12.5)).foregroundColor(.pkDanger)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.bottom, 8)
                    }

                    GradientButton(title: "Create Account") { doRegister() }
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
        }
        .background(Color.pkBg)
        .scrollDismissesKeyboard(.interactively)
    }

    private var passwordChecklist: some View {
        VStack(alignment: .leading, spacing: 5) {
            ForEach(InputParsing.passwordRules, id: \.label) { rule in
                let met = rule.check(appState.regPassword)
                HStack(spacing: 6) {
                    Image(systemName: met ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(met ? .pkSuccess : .pkSub)
                    Text(rule.label).foregroundColor(met ? .pkText : .pkSub)
                }
                .font(.system(size: 12.5))
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(rule.label), \(met ? "done" : "not yet")")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func doRegister() {
        do {
            let user = try AuthController(context: modelContext).register(
                name: appState.regName, mobile: appState.regMobile, municipality: appState.regMunicipality,
                province: appState.regProvince, landingSite: appState.regLanding,
                fisherfolkID: appState.regFID, password: appState.regPassword,
                role: appState.regRole, businessName: appState.regBusiness)
            appState.registerError = nil
            appState.applyUser(user)
            UserDefaults.standard.set(user.id.uuidString, forKey: AppState.rememberedUserKey)
            appState.showWelcomeTour = true
            appState.phase = .main
            let password = appState.regPassword
            appState.regPassword = ""
            Task { await SyncController.connectAndSync(user: user, password: password, appState: appState, context: modelContext) }
        } catch {
            appState.registerError = error.localizedDescription
        }
    }
}
