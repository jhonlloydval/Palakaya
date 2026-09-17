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
                    PKTextField(placeholder: "Juan Dela Cruz", text: $appState.regName).pkField("Full Name")
                    PKTextField(placeholder: "09XX XXX XXXX", text: $appState.regMobile, keyboard: .phonePad).pkField("Mobile Number")
                    PKTextField(placeholder: "Bauan", text: $appState.regMunicipality).pkField("Municipality")
                    PKTextField(placeholder: "Batangas, CALABARZON", text: $appState.regProvince).pkField("Province / Region")
                    PKTextField(placeholder: "Sabang Landing Site", text: $appState.regLanding).pkField("Home Port / Landing Site")
                    PKTextField(placeholder: "Optional", text: $appState.regFID).pkField("Fisherfolk ID (if applicable)")
                    PKTextField(placeholder: "Create a password", text: $appState.regPassword, isSecure: true).pkField("Password")

                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "lock.fill").foregroundColor(.pkDark)
                        Text("Your personal catch records stay private. Government reports use anonymized regional data.")
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

    private func doRegister() {
        guard !appState.regName.trimmingCharacters(in: .whitespaces).isEmpty,
              !appState.regMobile.trimmingCharacters(in: .whitespaces).isEmpty,
              !appState.regPassword.isEmpty else {
            appState.registerError = "Please fill in your name, mobile number, and password."
            return
        }
        let mobile = appState.regMobile
        let descriptor = FetchDescriptor<UserAccount>(predicate: #Predicate { $0.mobile == mobile })
        if let existing = try? modelContext.fetch(descriptor), !existing.isEmpty {
            appState.registerError = "An account with that mobile number already exists."
            return
        }
        let user = UserAccount(
            fullName: appState.regName,
            mobile: appState.regMobile,
            password: appState.regPassword,
            municipality: appState.regMunicipality,
            province: appState.regProvince,
            landingSite: appState.regLanding,
            fisherfolkID: appState.regFID
        )
        modelContext.insert(user)
        try? modelContext.save()

        let welcome = AdvisorMessageRecord(isUser: false, text: "Kamusta, \(user.fullName.split(separator: " ").first.map(String.init) ?? "there"). Ano ang gusto mong malaman?")
        modelContext.insert(welcome)
        try? modelContext.save()

        appState.registerError = nil
        appState.applyUser(user)
        appState.phase = .main
    }
}
