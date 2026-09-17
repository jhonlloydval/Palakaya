import Foundation

struct FairPriceInfo {
    var low: Int
    var high: Int
    var mid: Int
    var week: Double
    var history: [Int]
}

let FAIR_DB: [String: FairPriceInfo] = [
    "Galunggong": FairPriceInfo(low: 180, high: 205, mid: 192, week: 6.2, history: [176, 182, 188, 185, 192, 190, 192]),
    "Tamban":     FairPriceInfo(low: 150, high: 170, mid: 160, week: -1.1, history: [163, 162, 160, 161, 159, 158, 160]),
    "Tulingan":   FairPriceInfo(low: 198, high: 215, mid: 210, week: 2.8, history: [203, 205, 206, 208, 209, 211, 210]),
    "Bisugo":     FairPriceInfo(low: 190, high: 215, mid: 202, week: 1.0, history: [199, 200, 201, 200, 203, 204, 202]),
    "Bangus":     FairPriceInfo(low: 170, high: 185, mid: 178, week: -1.3, history: [181, 180, 179, 178, 177, 179, 178]),
    "Alumahan":   FairPriceInfo(low: 160, high: 180, mid: 170, week: 0.5, history: [168, 169, 170, 171, 169, 170, 170]),
]

let RECENT_SPECIES = ["Galunggong", "Tamban", "Tulingan", "Bisugo"]
let ALL_SPECIES = Array(FAIR_DB.keys).sorted()

struct OtherListing: Identifiable {
    var id: String
    var species: String
    var weight: Double
    var price: Int
    var seller: String
    var rating: Double
    var site: String
    var distance: String
    var fair: Bool
    var fresh: Bool = false
}

let OTHER_LISTINGS: [OtherListing] = [
    OtherListing(id: "m1", species: "Tulingan", weight: 18, price: 205, seller: "Mang Roberto", rating: 4.8, site: "Batangas City", distance: "2.4 km", fair: true),
    OtherListing(id: "m2", species: "Bangus", weight: 15, price: 178, seller: "Aling Fely", rating: 4.6, site: "Anilao", distance: "3.1 km", fair: true, fresh: true),
    OtherListing(id: "m3", species: "Galunggong", weight: 9, price: 168, seller: "Kuya Dindo", rating: 4.9, site: "Mabini", distance: "4.7 km", fair: false),
]

struct Buyer: Identifiable, Hashable {
    var id: String
    var name: String
    var verified: Bool
    var rating: Double
    var trans: Int
    var offer: Int
    var distance: String
    var fair: Bool
    var type: String
}

let BUYERS: [Buyer] = [
    Buyer(id: "b1", name: "Liza's Seafood Stall", verified: true, rating: 4.8, trans: 127, offer: 198, distance: "1.8 km", fair: true, type: "Retailer"),
    Buyer(id: "b2", name: "Coastal Fresh Trading", verified: true, rating: 4.5, trans: 64, offer: 165, distance: "3.5 km", fair: false, type: "Cooperative"),
]

struct NotificationItem: Identifiable {
    var id: String
    var kind: String
    var text: String
    var time: String
}

let NOTIFS: [NotificationItem] = [
    NotificationItem(id: "n1", kind: "PRICE UPDATE", text: "Galunggong prices increased 6% this week.", time: "1h ago"),
    NotificationItem(id: "n2", kind: "BUYER INTEREST", text: "Liza's Seafood Stall is interested in your Tulingan listing.", time: "3h ago"),
    NotificationItem(id: "n3", kind: "SALE", text: "Your Tamban sale has been recorded.", time: "5h ago"),
    NotificationItem(id: "n4", kind: "SYNC", text: "3 offline catch records were successfully synced.", time: "Yesterday"),
]

let ADVISOR_SUGGESTIONS = [
    "Magkano ang fair price ng Galunggong ngayon?",
    "Aling fishing ground ang madalas kong magandang huli?",
    "Bakit mababa ang presyo ng huling benta ko?",
    "Anong isda ang mataas ang presyo ngayong linggo?",
]

/// Very small rule-based advisor. Looks for species / keywords in the question
/// and answers using the local FAIR_DB, so answers are always grounded in
/// real numbers already in the app instead of being invented.
enum Advisor {
    static func reply(to question: String, catches: [CatchRecord]) -> String {
        let q = question.lowercased()

        // Try to detect a species mentioned in the question.
        if let species = FAIR_DB.keys.first(where: { q.contains($0.lowercased()) }) {
            let f = FAIR_DB[species]!
            let trend = f.week >= 0 ? "up \(String(format: "%.1f", f.week))%" : "down \(String(format: "%.1f", abs(f.week)))%"
            return "Based on recent Palakaya transactions in Batangas, \(species) is currently selling around ₱\(f.low)–₱\(f.high)/kg (average ₱\(f.mid)). Prices are \(trend) this week."
        }

        if q.contains("fishing ground") || q.contains("saan") || q.contains("ground") {
            let grounds = Dictionary(grouping: catches, by: { $0.ground })
                .mapValues { $0.reduce(0.0) { $0 + $1.weight } }
                .sorted { $0.value > $1.value }
            if let best = grounds.first {
                return "Your best-performing fishing ground so far is \(best.key), with \(String(format: "%.1f", best.value)) kg logged. Keep tracking your catches here to refine this over time."
            }
            return "Log a few more catches with their fishing ground noted, and I can tell you which spot has been most productive for you."
        }

        if q.contains("mataas") || q.contains("highest") || q.contains("linggo") || q.contains("week") {
            if let top = FAIR_DB.max(by: { $0.value.mid < $1.value.mid }) {
                return "\(top.key) has the highest average price this week at around ₱\(top.value.mid)/kg. Galunggong is also trending upward, up \(String(format: "%.1f", FAIR_DB["Galunggong"]?.week ?? 0))% this week."
            }
        }

        if q.contains("mababa") || q.contains("below") || q.contains("bakit") {
            if let lastSale = catches.first(where: { $0.status == .sold }), let fair = lastSale.fair, let price = lastSale.price {
                if price < Double(fair.low) {
                    return "Your last sale of \(lastSale.species) was at ₱\(Int(price))/kg, which is below today's benchmark range of ₱\(fair.low)–₱\(fair.high)/kg. Try comparing offers from more buyers before accepting next time — the Buyer Matches screen shows nearby offers side by side."
                }
                return "Your last sale of \(lastSale.species) at ₱\(Int(price))/kg was actually within the fair range of ₱\(fair.low)–₱\(fair.high)/kg — nicely done."
            }
            return "I don't see a recorded sale yet to compare. Once you record a sale, I can tell you how it lined up with the local benchmark."
        }

        return "Kamusta! Ask me about a specific species (e.g. \"Magkano ang Galunggong?\"), your fishing grounds, or a recent sale, and I'll check it against your catch records and today's market prices."
    }
}
