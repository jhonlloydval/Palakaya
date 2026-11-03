import Foundation
import SwiftData

/// Sample catches for presenting the app. They stay on this phone and never upload,
/// so they cannot affect anyone's fair prices.
@MainActor
struct DemoController {
    let context: ModelContext
    private static let idsKey = "demoCatchIDs"

    static var sampleIDs: Set<UUID> {
        get { Set((UserDefaults.standard.stringArray(forKey: idsKey) ?? []).compactMap(UUID.init)) }
        set { UserDefaults.standard.set(newValue.map(\.uuidString), forKey: idsKey) }
    }

    func sampleCount(ownerID: UUID?) -> Int {
        let ids = Self.sampleIDs
        let all = (try? context.fetch(FetchDescriptor<CatchRecord>())) ?? []
        return all.filter { ids.contains($0.id) && $0.ownerID == ownerID }.count
    }

    /// Adds three weeks of realistic catches: some sold, some listed, some still available.
    func addSampleData(ownerID: UUID?, landingSite: String) throws {
        let ground = landingSite.isEmpty ? "Nearshore fishing ground" : "Off \(landingSite)"
        // (days ago, hour, species, kg, status, ₱/kg, buyer)
        let rows: [(Int, Int, String, Double, CatchStatus, Double?, String?)] = [
            (0, 5, "Galunggong", 14.5, .available, nil, nil),
            (0, 6, "Tulingan", 9.0, .listed, 210, nil),
            (1, 5, "Tamban", 11.0, .sold, 162, "Aling Rosa's Talipapa"),
            (3, 6, "Bisugo", 6.5, .sold, 205, "Bayan Fresh Fish Stall"),
            (5, 5, "Galunggong", 16.0, .sold, 188, "Dalahican Fishers Cooperative"),
            (8, 6, "Alumahan", 8.0, .sold, 150, "Kusina ni Nena Carinderia"),
            (11, 5, "Tulingan", 12.5, .sold, 212, "Bayan Fresh Fish Stall"),
            (15, 6, "Bangus", 10.0, .sold, 176, "Aling Rosa's Talipapa"),
            (19, 5, "Galunggong", 13.0, .sold, 194, "Dalahican Fishers Cooperative"),
        ]
        let calendar = Calendar.current
        var ids = Self.sampleIDs
        for r in rows {
            let day = calendar.date(byAdding: .day, value: -r.0, to: Date()) ?? Date()
            let date = calendar.date(bySettingHour: r.1, minute: 30, second: 0, of: day) ?? day
            let sold = r.4 == .sold
            let alignment = sold ? r.5.flatMap { p in FAIR_DB[r.2].map { Int(p / Double($0.mid) * 100) } } : nil
            let record = CatchRecord(species: r.2, weight: r.3, ground: ground, timeLabel: date.pkTimeLabel,
                                     dateLogged: date, status: r.4, price: r.5,
                                     saleAmount: sold ? r.5.map { $0 * r.3 } : nil,
                                     buyerName: r.6, alignment: alignment)
            record.ownerID = ownerID
            record.needsSync = false
            context.insert(record)
            ids.insert(record.id)
        }
        try context.save()
        Self.sampleIDs = ids
    }

    func removeSampleData() throws {
        let ids = Self.sampleIDs
        let all = try context.fetch(FetchDescriptor<CatchRecord>())
        for record in all where ids.contains(record.id) { context.delete(record) }
        try context.save()
        Self.sampleIDs = []
    }
}
