import SwiftUI
import SwiftData

enum ProfileSection: String, Hashable {
    case personal = "Personal Information"
    case fisherfolk = "Fisherfolk Details"
    case landing = "Landing Site"
    case verification = "Buyer Verification"
    case connectivity = "Connectivity & Offline Data"
    case privacy = "Privacy"
    case help = "Help Center"
    case about = "About Palakaya"
    case demo = "Demo Tools"
}

/// The page behind each Profile menu row.
struct ProfileInfoView: View {
    var section: ProfileSection

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                switch section {
                case .personal: PersonalInfoSection()
                case .fisherfolk: FisherfolkSection()
                case .landing: LandingSiteSection()
                case .verification: VerificationSection()
                case .connectivity: ConnectivitySection()
                case .privacy: PrivacySection()
                case .help: HelpSection()
                case .about: AboutSection()
                case .demo: DemoSection()
                }
            }
            .padding(.horizontal, 20).padding(.top, 12).padding(.bottom, 32)
        }
        .background(Color.pkBg)
        .navigationTitle(section.rawValue)
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
    }
}

// MARK: - Shared pieces

private struct Panel<Content: View>: View {
    var title: String?
    @ViewBuilder var content: () -> Content
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let title { Text(title).font(.system(size: 17, weight: .bold)).foregroundColor(.pkText) }
            content()
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.pkSurface)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.pkBorder))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

private struct Fact: View {
    var icon: String
    var text: String
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon).font(.system(size: 16)).foregroundColor(.pkDark).frame(width: 22)
            Text(text).font(.system(size: 15)).foregroundColor(.pkText).lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct ValueRow: View {
    var label: String
    var value: String
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label).font(.system(size: 15)).foregroundColor(.pkSub)
            Spacer(minLength: 12)
            Text(value.isEmpty ? "Not added" : value).font(.system(size: 15, weight: .semibold))
                .foregroundColor(value.isEmpty ? .pkSub : .pkText).multilineTextAlignment(.trailing)
        }
    }
}

/// The signed-in account, for the pages that edit it.
private struct CurrentUser {
    static func find(_ users: [UserAccount], _ id: UUID?) -> UserAccount? { users.first { $0.id == id } }
}

// MARK: - Personal information

private struct PersonalInfoSection: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [UserAccount]
    @State private var name = ""
    @State private var municipality = ""
    @State private var province = ""
    @State private var message: (text: String, ok: Bool)?
    @State private var showPassword = false

    var body: some View {
        Panel(title: "Your details") {
            PKTextField(placeholder: "Juan Dela Cruz", text: $name).pkField("Full name")
            VStack(alignment: .leading, spacing: 6) {
                Text("Mobile number").font(.system(size: 13, weight: .medium)).foregroundColor(.pkSub)
                Text(appState.currentUserMobile).font(.system(size: 16, weight: .semibold))
                Text("This is your login, so it can't be changed here.").font(.system(size: 12.5)).foregroundColor(.pkSub)
            }
            .padding(.bottom, 16)
            PKTextField(placeholder: "Lucena City", text: $municipality).pkField("Municipality")
            PKTextField(placeholder: "Quezon, CALABARZON", text: $province).pkField("Province / Region")
            if let message {
                Text(message.text).font(.system(size: 13.5, weight: .medium))
                    .foregroundColor(message.ok ? .pkSuccess : .pkDanger)
            }
            PrimaryButton(title: "Save changes") { save() }
        }
        .onAppear(perform: load)

        Panel(title: "Password") {
            Text("Use at least 8 characters with an uppercase letter, a lowercase letter and a number.")
                .font(.system(size: 14)).foregroundColor(.pkSub)
            GhostButton(title: "Change password", systemImage: "key.fill") { showPassword = true }
        }
        .sheet(isPresented: $showPassword) { ChangePasswordSheet() }
    }

    private func load() {
        name = appState.currentUserName
        municipality = appState.currentUserMunicipality
        province = appState.currentUserProvince
    }

    private func save() {
        guard let user = CurrentUser.find(users, appState.currentUserID) else { return }
        do {
            try AuthController(context: modelContext).updateProfile(
                user, name: name, municipality: municipality, province: province,
                landingSite: user.landingSite, fisherfolkID: user.fisherfolkID)
            appState.applyUser(user)
            appState.tab = .profile
            message = ("Saved.", true)
            Task { try? await SyncService.pushProfile(user) }
        } catch {
            message = (error.localizedDescription, false)
        }
    }
}

private struct ChangePasswordSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var users: [UserAccount]
    @State private var current = ""
    @State private var new = ""
    @State private var error: String?
    @State private var saving = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    PKTextField(text: $current, isSecure: true).pkField("Current password")
                    PKTextField(placeholder: "e.g. Kahitano1Jl", text: $new, isSecure: true).pkField("New password")
                    ForEach(InputParsing.passwordRules, id: \.label) { rule in
                        let met = rule.check(new)
                        HStack(spacing: 6) {
                            Image(systemName: met ? "checkmark.circle.fill" : "circle").foregroundColor(met ? .pkSuccess : .pkSub)
                            Text(rule.label).foregroundColor(met ? .pkText : .pkSub)
                        }
                        .font(.system(size: 13.5))
                        .padding(.bottom, 5)
                    }
                    if let error {
                        Text(error).font(.system(size: 13.5)).foregroundColor(.pkDanger).padding(.top, 8)
                    }
                    PrimaryButton(title: saving ? "Saving…" : "Change password", isDisabled: saving) { save() }
                        .padding(.top, 20)
                }
                .padding(20)
            }
            .background(Color.pkBg)
            .navigationTitle("Change password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        }
    }

    private func save() {
        guard let user = CurrentUser.find(users, appState.currentUserID) else { return }
        saving = true
        Task {
            defer { saving = false }
            do {
                try await AuthController(context: modelContext).changePassword(user, current: current, new: new)
                dismiss()
            } catch let e as AuthError {
                error = e.localizedDescription
            } catch {
                self.error = "Could not reach the server to change your cloud password. Connect to the internet and try again."
            }
        }
    }
}

// MARK: - Fisherfolk details

private struct FisherfolkSection: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [UserAccount]
    @State private var fid = ""
    @State private var saved = false

    var body: some View {
        Panel(title: "FishR registration") {
            Text(appState.currentUserFID.isEmpty ? "Not registered in the app yet" : "Registered municipal fisher")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(appState.currentUserFID.isEmpty ? .pkWarning : .pkSuccess)
            PKTextField(placeholder: "e.g. 0456-2024-00123", text: $fid).pkField("Fisherfolk ID number")
            if saved { Text("Saved.").font(.system(size: 13.5, weight: .medium)).foregroundColor(.pkSuccess) }
            PrimaryButton(title: "Save ID") { save() }
        }
        .onAppear { fid = appState.currentUserFID }

        Panel(title: "What is FishR?") {
            Fact(icon: "person.text.rectangle", text: "FishR is BFAR's national registry of municipal fisherfolk. Your ID shows you are a registered fisher in your town.")
            Fact(icon: "gift.fill", text: "Registered fishers are the ones considered first for government programs such as fuel assistance, boats and gear, insurance and livelihood support.")
            Fact(icon: "building.columns.fill", text: "To register, visit your Municipal Agriculture Office. Bring a valid ID, a barangay certificate of residency and a recent 1×1 photo.")
        }
    }

    private func save() {
        guard let user = CurrentUser.find(users, appState.currentUserID) else { return }
        try? AuthController(context: modelContext).updateProfile(
            user, name: user.fullName, municipality: user.municipality, province: user.province,
            landingSite: user.landingSite, fisherfolkID: fid)
        appState.applyUser(user)
        appState.tab = .profile
        saved = true
        Task { try? await SyncService.pushProfile(user) }
    }
}

// MARK: - Landing site

private struct LandingSiteSection: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [UserAccount]
    @Query(sort: \CatchRecord.dateLogged, order: .reverse) private var allCatches: [CatchRecord]
    @State private var landing = ""
    @State private var saved = false

    private var catches: [CatchRecord] { allCatches.owned(by: appState.currentUserID) }

    private var grounds: [(name: String, kg: Double, trips: Int)] {
        Dictionary(grouping: catches, by: \.ground)
            .map { (name: $0.key, kg: $0.value.reduce(0) { $0 + $1.weight }, trips: $0.value.count) }
            .sorted { $0.kg > $1.kg }
    }

    var body: some View {
        Panel(title: "Home port") {
            PKTextField(placeholder: "Dalahican Landing Site", text: $landing).pkField("Where you usually land your catch")
            if saved { Text("Saved.").font(.system(size: 13.5, weight: .medium)).foregroundColor(.pkSuccess) }
            PrimaryButton(title: "Save landing site") { save() }
            Text("Buyers see this as the pickup place on your listings, and new catches start with it as the fishing ground.")
                .font(.system(size: 13)).foregroundColor(.pkSub)
        }
        .onAppear { landing = appState.currentUserLandingSite }

        Panel(title: "Your fishing grounds") {
            if grounds.isEmpty {
                Text("Log a catch and the places you fish will show up here, with how much you caught at each.")
                    .font(.system(size: 15)).foregroundColor(.pkSub)
            } else {
                ForEach(Array(grounds.enumerated()), id: \.offset) { i, g in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(g.name).font(.system(size: 16, weight: .semibold)).foregroundColor(.pkText)
                            Text("\(g.trips) \(g.trips == 1 ? "catch" : "catches") logged").font(.system(size: 13)).foregroundColor(.pkSub)
                        }
                        Spacer()
                        Text("\(g.kg.pkTrimmed) kg").font(.system(size: 16, weight: .bold)).foregroundColor(.pkDark)
                    }
                    if i < grounds.count - 1 { Divider().overlay(Color.pkBorder) }
                }
            }
        }
    }

    private func save() {
        guard let user = CurrentUser.find(users, appState.currentUserID) else { return }
        try? AuthController(context: modelContext).updateProfile(
            user, name: user.fullName, municipality: user.municipality, province: user.province,
            landingSite: landing, fisherfolkID: user.fisherfolkID)
        appState.applyUser(user)
        appState.tab = .profile
        saved = true
        Task { try? await SyncService.pushProfile(user) }
    }
}

// MARK: - Buyer verification

private struct VerificationSection: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Panel(title: appState.currentBusinessName.isEmpty ? "Your business" : appState.currentBusinessName) {
            HStack(spacing: 8) {
                Image(systemName: appState.currentUserVerified ? "checkmark.seal.fill" : "clock.fill")
                Text(appState.currentUserVerified ? "Verified buyer" : "Waiting for verification")
            }
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(appState.currentUserVerified ? .pkSuccess : .pkWarning)
        }
        Panel(title: "How to get verified") {
            Fact(icon: "1.circle.fill", text: "Prepare a photo of your business permit, cooperative registration or a government ID.")
            Fact(icon: "2.circle.fill", text: "Send it to your Municipal Agriculture Office or the Palakaya team, with the mobile number you signed up with.")
            Fact(icon: "3.circle.fill", text: "Once checked, the Verified badge appears on your profile and on every offer you send.")
        }
        Panel(title: "Why it matters") {
            Fact(icon: "hand.thumbsup.fill", text: "Fishers accept offers from verified buyers more often, because they know who they are selling to.")
        }
    }
}

// MARK: - Connectivity

private struct ConnectivitySection: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query private var allCatches: [CatchRecord]
    @State private var syncing = false

    private var mine: [CatchRecord] { allCatches.owned(by: appState.currentUserID) }
    private var pending: Int { mine.filter(\.needsSync).count }
    private var cloudOn: Bool { AppConfig.isCloudEnabled && SupabaseClient.shared.isSignedIn }

    var body: some View {
        Panel(title: "Status") {
            ValueRow(label: "Internet", value: appState.isOffline ? "No signal" : "Connected")
            Divider().overlay(Color.pkBorder)
            ValueRow(label: "Cloud backup", value: cloudOn ? "On" : "Off (saved on this phone only)")
            Divider().overlay(Color.pkBorder)
            ValueRow(label: "Catches on this phone", value: "\(mine.count)")
            Divider().overlay(Color.pkBorder)
            ValueRow(label: "Waiting to upload", value: pending == 0 ? "None" : "\(pending)")
            PrimaryButton(title: syncing ? "Syncing…" : "Sync now", systemImage: "arrow.triangle.2.circlepath",
                          isDisabled: syncing || !cloudOn) {
                syncing = true
                Task {
                    await SyncController.sync(appState: appState, context: modelContext)
                    syncing = false
                }
            }
            .padding(.top, 4)
        }
        Panel(title: "How offline mode works") {
            Fact(icon: "iphone", text: "Every catch, listing and sale is saved on your phone first, so the app works out at sea with no signal.")
            Fact(icon: "icloud.and.arrow.up", text: "When you get signal again, waiting records upload on their own. You can also tap Sync now, or the Wi-Fi button on Home.")
            Fact(icon: "arrow.down.circle", text: "If you change phones, log in with the same mobile number and password and your catches come back.")
        }
    }
}

// MARK: - Privacy

private struct PrivacySection: View {
    var body: some View {
        Panel(title: "Who sees what") {
            Fact(icon: "person.fill", text: "Only you see your full catch records, sales and Advisor chats.")
            Fact(icon: "storefront.fill", text: "Buyers see only what you list for sale: species, kilos, price and pickup place, plus your first name, town and mobile number so they can contact you.")
            Fact(icon: "building.columns.fill", text: "BFAR and local fisheries offices see totals by town, species and month, never names. Groups with fewer than 5 catches are hidden.")
        }
        Panel(title: "What Palakaya stores") {
            Fact(icon: "checkmark.circle", text: "Your name, mobile number, town, landing site and optional Fisherfolk ID.")
            Fact(icon: "checkmark.circle", text: "The catches, listings, offers and sales you record. Catch photos stay on your phone.")
            Fact(icon: "xmark.circle", text: "No location tracking, no contacts, and your password is never stored as plain text.")
        }
        Panel(title: "Your rights") {
            Fact(icon: "doc.text.magnifyingglass", text: "Under the Data Privacy Act of 2012, you can ask to see, correct or delete your data. Contact the Palakaya team with the mobile number you signed up with.")
        }
    }
}

// MARK: - Help

private struct HelpSection: View {
    private let faqs: [(String, String)] = [
        ("How do I log a catch?", "On Home, tap Log Catch. Pick the fish (or type its name if it isn't listed), enter the kilos, check the details and tap Save."),
        ("What is the fair price?", "It's the usual price range for that fish this week. When there are at least 5 recent sales in Palakaya, it comes from those real sales. Otherwise it's a regional estimate."),
        ("How do I sell my catch?", "Open the catch and tap List Catch for Sale. Set your price, and buyers near you can send offers. Accept the best one, then record the sale when you're paid."),
        ("Can I use the app without signal?", "Yes. Everything is saved on your phone and uploads when you have signal again."),
        ("What can the Advisor answer?", "Questions about your catch, fish prices, selling and fishing grounds, in English or Filipino. It won't answer topics outside fishing."),
        ("How do I change my password?", "Go to Profile, then Personal Information, then Change password."),
        ("I forgot my password.", "Password reset by text message is coming soon. For now, ask the Palakaya team to reset it, using the mobile number you signed up with."),
    ]

    var body: some View {
        Panel(title: "Common questions") {
            ForEach(Array(faqs.enumerated()), id: \.offset) { i, faq in
                DisclosureGroup {
                    Text(faq.1).font(.system(size: 15)).foregroundColor(.pkSub).lineSpacing(3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 6)
                } label: {
                    Text(faq.0).font(.system(size: 16, weight: .semibold)).foregroundColor(.pkText)
                        .multilineTextAlignment(.leading)
                }
                .tint(.pkDark)
                .padding(.vertical, 4)
                if i < faqs.count - 1 { Divider().overlay(Color.pkBorder) }
            }
        }
        Panel(title: "Need more help?") {
            Fact(icon: "building.columns.fill", text: "Your Municipal Agriculture Office can help with FishR registration, permits and fisheries programs.")
            Fact(icon: "exclamationmark.triangle.fill", text: "For storms and emergencies at sea, follow PAGASA and call the Philippine Coast Guard.")
        }
    }
}

// MARK: - Demo tools

private struct DemoSection: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @State private var samples = 0
    @State private var message: String?

    var body: some View {
        Panel(title: "Sample data") {
            Text("Adds three weeks of example catches and sales to this account so every screen has something to show. They stay on this phone and never upload, so real fair prices are not affected.")
                .font(.system(size: 15)).foregroundColor(.pkSub).lineSpacing(2)
            if appState.isBuyer {
                Text("Sample catches are for fisher accounts. Log in as a fisher to use them.")
                    .font(.system(size: 14, weight: .medium)).foregroundColor(.pkWarning)
            } else if samples > 0 {
                Text("\(samples) sample catches are on this account.").font(.system(size: 14, weight: .semibold)).foregroundColor(.pkSuccess)
                GhostButton(title: "Remove sample data", systemImage: "trash") { remove() }
            } else {
                PrimaryButton(title: "Fill with sample data", systemImage: "wand.and.stars") { add() }
            }
            if let message { Text(message).font(.system(size: 13.5)).foregroundColor(.pkSub) }
        }
        Panel(title: "Walkthroughs") {
            GhostButton(title: "Replay the welcome tour", systemImage: "play.circle") { appState.showWelcomeTour = true }
            GhostButton(title: "See the intro screens again", systemImage: "sparkles.rectangle.stack") { appState.logout() }
            Text("The intro screens are shown on the login side, so this logs you out first.")
                .font(.system(size: 13)).foregroundColor(.pkSub)
        }
        Panel(title: "Good to show") {
            Fact(icon: "moon.fill", text: "Use Appearance on the Profile page to switch between Light and Dark Mode.")
            Fact(icon: "wifi.slash", text: "Turn on Airplane Mode and log a catch: it saves, then uploads when you're back online.")
            Fact(icon: "sparkles", text: "Ask the Advisor something off-topic to show it stays on fishing.")
        }
        .onAppear(perform: count)
    }

    private func count() { samples = DemoController(context: modelContext).sampleCount(ownerID: appState.currentUserID) }

    private func add() {
        do {
            try DemoController(context: modelContext).addSampleData(ownerID: appState.currentUserID, landingSite: appState.currentUserLandingSite)
            message = "Added. Check Home, My Catch and Reports."
        } catch { message = "Could not add sample data." }
        count()
    }

    private func remove() {
        do {
            try DemoController(context: modelContext).removeSampleData()
            message = "Sample data removed."
        } catch { message = "Could not remove sample data." }
        count()
    }
}

// MARK: - About

private struct AboutSection: View {
    private let stats: [(String, String)] = [
        ("600,000 t", "less fish landed in 2023 than in 2010"),
        ("350,000+", "fishing families below the poverty line"),
        ("₱2,500–7,000", "a month is what many municipal fishers earn"),
        ("49–52", "years old, the average Filipino fisher"),
    ]

    private let features: [(String, String, String)] = [
        ("water.waves", "Log every catch", "Species, kilos, fishing ground, time and a photo, saved even with no signal."),
        ("tag.fill", "Fair-price check", "A price range for each fish from real recent sales in your province."),
        ("storefront.fill", "Direct to buyers", "List your catch and get offers from verified stalls, carinderias and cooperatives."),
        ("checkmark.seal.fill", "Fair-sale score", "Every sale is scored against the fair price, so you know if you were paid right."),
        ("sparkles", "Advisor", "Ask about prices, grounds and selling in English or Filipino."),
        ("chart.bar.doc.horizontal.fill", "Reports", "Monthly kilos, income and best grounds, ready to share."),
        ("building.columns.fill", "Data for BFAR and LGUs", "Anonymous totals by town and species, never names."),
    ]

    var body: some View {
        VStack(spacing: 10) {
            Image("PalakayaLogo").resizable().scaledToFit().frame(width: 170)
                .accessibilityLabel("Palakaya. Catch. Connect. Get a Fair Price.")
            Text("A catch log and fair-price marketplace for Filipino municipal fishers.")
                .font(.system(size: 16, weight: .medium)).foregroundColor(.pkSub).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)

        VStack(alignment: .leading, spacing: 12) {
            Text("The catch is theirs. The price usually isn't.")
                .font(.system(size: 22, weight: .heavy)).foregroundColor(.white)
            Text("Under the consignacion system, the trader who sells the fish sets its price, not the fisher who caught it. Fishers go home without knowing if they were paid fairly, and fisheries offices can't see where prices fall short.")
                .font(.system(size: 15)).foregroundColor(.white.opacity(0.88)).lineSpacing(3)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LinearGradient.pkBrand)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible())], spacing: 12) {
            ForEach(stats, id: \.0) { value, label in
                VStack(alignment: .leading, spacing: 4) {
                    Text(value).font(.system(size: 20, weight: .heavy)).foregroundColor(.pkDark)
                        .minimumScaleFactor(0.8).lineLimit(1)
                    Text(label).font(.system(size: 13)).foregroundColor(.pkSub)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(14)
                .frame(maxWidth: .infinity, minHeight: 104, alignment: .topLeading)
                .background(Color.pkSurface)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.pkBorder))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .accessibilityElement(children: .combine)
            }
        }
        Text("Sources: Philstar, IndexBox and The New Humanitarian, 2026.").font(.system(size: 12)).foregroundColor(.pkSub)

        Panel(title: "What Palakaya does") {
            ForEach(features, id: \.1) { icon, title, detail in
                HStack(alignment: .top, spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.pkSurface2).frame(width: 44, height: 44)
                        Image(systemName: icon).font(.system(size: 18)).foregroundColor(.pkDark)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title).font(.system(size: 16, weight: .bold)).foregroundColor(.pkText)
                        Text(detail).font(.system(size: 14)).foregroundColor(.pkSub).lineSpacing(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .accessibilityElement(children: .combine)
            }
        }

        Panel(title: "Who it's for") {
            Fact(icon: "figure.fishing", text: "Municipal fishers, as defined in the Fisheries Code (RA 8550), including those who sell through consignacion today.")
            Fact(icon: "cart.fill", text: "Buyers: market vendors, carinderias, wholesalers and fisherfolk cooperatives.")
            Fact(icon: "building.columns.fill", text: "BFAR and local fisheries offices, who get a live, anonymous view of catch and prices.")
        }

        Panel(title: "How fair prices work") {
            Fact(icon: "chart.bar.fill", text: "For each fish, Palakaya takes sales recorded in the last 30 days and shows the middle half of those prices.")
            Fact(icon: "mappin.and.ellipse", text: "Your own province is used first. With fewer than 5 sales there, it uses all Palakaya sales, then a regional estimate, and always says which.")
        }

        Panel(title: "Built with") {
            Fact(icon: "swift", text: "SwiftUI and SwiftData on iPhone, works offline.")
            Fact(icon: "server.rack", text: "Supabase for cloud backup, the marketplace and the Advisor.")
        }

        VStack(spacing: 4) {
            Text("Made by Jhon Lloyd Valencia").font(.system(size: 15, weight: .semibold)).foregroundColor(.pkText)
            Text("Lucena City, Quezon").font(.system(size: 13)).foregroundColor(.pkSub)
            Text("Version 2.0").font(.system(size: 13)).foregroundColor(.pkSub)
            Text("Intro photos: Gerald Escamos, Hector John Periquin and Xavier Smet on Unsplash.")
                .font(.system(size: 12)).foregroundColor(.pkSub).multilineTextAlignment(.center).padding(.top, 6)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }
}
