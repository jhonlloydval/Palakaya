import SwiftUI
import SwiftData

@main
struct PalakayaApp: App {
    let container: ModelContainer
    @State private var appState = AppState()

    init() {
        do {
            container = try ModelContainer(for: UserAccount.self, CatchRecord.self, AdvisorMessageRecord.self)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
        upgradeLegacyAccounts()
        seedIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .modelContainer(container)
        }
    }

    /// Accounts saved by older versions of the app kept the mobile number as typed ("0917 234 5678")
    /// and the password as plain text, so login could not find or verify them. Normalizes and hashes them once.
    private func upgradeLegacyAccounts() {
        let context = ModelContext(container)
        let accounts = (try? context.fetch(FetchDescriptor<UserAccount>())) ?? []
        var changed = false
        for user in accounts {
            let isHashed = user.passwordHash.count == 64 && user.passwordHash.allSatisfy(\.isHexDigit)
            guard !isHashed else { continue }
            let mobile = InputParsing.normalizedMobile(user.mobile)
            user.mobile = mobile
            user.passwordHash = PasswordHasher.hash(user.passwordHash, salt: mobile)
            changed = true
        }
        if changed { try? context.save() }
    }

    /// Seeds a demo account (matching the original prototype's login placeholder)
    /// so the app is usable immediately on first launch.
    private func seedIfNeeded() {
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<UserAccount>()
        let existing = (try? context.fetch(descriptor)) ?? []
        guard existing.isEmpty else { return }

        let demoUser = UserAccount(
            fullName: "Mang Jose Dela Cruz",
            mobile: "09172345678",
            password: "password",
            municipality: "Bauan",
            province: "Batangas, CALABARZON",
            landingSite: "Sabang Landing Site",
            fisherfolkID: ""
        )
        context.insert(demoUser)

        // Fixed IDs match `supabase/seed_demo.sql`, so the cloud copy (and buyers' offers on the
        // Tulingan listing) line up with this phone after the first sync.
        // (id suffix, species, kg, ground, days ago, hour, minute, status, ₱/kg, buyer)
        let seedCatches: [(Int, String, Double, String, Int, Int, Int, CatchStatus, Double?, String?)] = [
            (4, "Tulingan", 18.0, "Batangas Bay", 0, 6, 5, .listed, 205, nil),
            (2, "Bisugo", 6.4, "Batangas Bay", 0, 6, 20, .available, nil, nil),
            (3, "Alumahan", 10.2, "Sabang Fishing Ground", 0, 6, 50, .available, nil, nil),
            (1, "Tamban", 8.0, "Sabang Fishing Ground", 1, 7, 10, .sold, 160, "Aling Nena's Talipapa"),
            (5, "Galunggong", 12.0, "Sabang Fishing Ground", 3, 5, 40, .sold, 190, "Liza's Seafood Stall"),
            (6, "Tulingan", 15.0, "Batangas Bay", 6, 6, 15, .sold, 208, "Coastal Fresh Trading Cooperative"),
            (7, "Galunggong", 10.0, "Sabang Fishing Ground", 10, 5, 55, .sold, 185, "Ate Mila's Carinderia"),
            (8, "Tamban", 9.0, "Sabang Fishing Ground", 14, 6, 30, .sold, 155, "Bay Fish Traders"),
            (9, "Bisugo", 7.0, "Batangas Bay", 20, 6, 10, .sold, 200, "Liza's Seafood Stall"),
        ]
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        for s in seedCatches {
            let day = calendar.date(byAdding: .day, value: -s.4, to: today) ?? today
            let date = calendar.date(bySettingHour: s.5, minute: s.6, second: 0, of: day) ?? day
            let amount = s.7 == .sold ? s.8.map { $0 * s.2 } : nil
            let alignment = s.7 == .sold ? s.8.flatMap { price in FAIR_DB[s.1].map { Int(price / Double($0.mid) * 100) } } : nil
            let c = CatchRecord(species: s.1, weight: s.2, ground: s.3, timeLabel: date.pkTimeLabel, dateLogged: date,
                                status: s.7, price: s.8, saleAmount: amount, buyerName: s.9, alignment: alignment)
            c.id = UUID(uuidString: String(format: "a0000000-0000-4000-8000-%012d", s.0)) ?? UUID()
            c.ownerID = demoUser.id
            context.insert(c)
        }

        let welcome = AdvisorMessageRecord(isUser: false, text: "Hi Jose! Ask me about your catch, fish prices or selling. You can write in English or Filipino.", ownerID: demoUser.id)
        context.insert(welcome)

        try? context.save()
    }
}
