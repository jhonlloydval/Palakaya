import Foundation
import SwiftData

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

/// Stores the conversation and asks `Advisor` for the reply.
struct AdvisorController {
    let context: ModelContext

    func ask(_ question: String, catches: [CatchRecord]) throws {
        context.insert(AdvisorMessageRecord(isUser: true, text: question))
        context.insert(AdvisorMessageRecord(isUser: false, text: Advisor.reply(to: question, catches: catches)))
        try context.save()
    }
}
