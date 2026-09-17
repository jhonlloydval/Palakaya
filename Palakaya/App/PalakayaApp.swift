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
        seedIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .modelContainer(container)
        }
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
            mobile: "0917 234 5678",
            password: "password",
            municipality: "Bauan",
            province: "Batangas, CALABARZON",
            landingSite: "Sabang Landing Site",
            fisherfolkID: ""
        )
        context.insert(demoUser)

        let seedCatches: [(String, Double, String, String, CatchStatus, Double?, Double?, String?, Int?, Int?)] = [
            ("Tamban", 8.0, "Sabang Fishing Ground", "7:10 AM", .sold, 160, 1280, "Aling Nena's Talipapa", 100, nil),
            ("Bisugo", 6.4, "Batangas Bay", "6:20 AM", .available, nil, nil, nil, nil, nil),
            ("Alumahan", 10.2, "Sabang Fishing Ground", "6:50 AM", .available, nil, nil, nil, nil, nil),
            ("Tulingan", 18.0, "Batangas Bay", "6:05 AM", .listed, 205, nil, nil, nil, 3),
        ]
        for s in seedCatches {
            let c = CatchRecord(species: s.0, weight: s.1, ground: s.2, timeLabel: s.3, status: s.4,
                                 price: s.5, saleAmount: s.6, buyerName: s.7, alignment: s.8, buyersInterested: s.9)
            context.insert(c)
        }

        let welcome = AdvisorMessageRecord(isUser: false, text: "Kamusta, Mang Jose. Ano ang gusto mong malaman?")
        context.insert(welcome)

        try? context.save()
    }
}
