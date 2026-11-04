import Foundation
import SwiftData

/// Offline rule-based advisor, used when the AI Advisor cannot be reached. Looks for species / keywords
/// in the question and answers using FAIR_DB, so answers stay grounded in numbers already in the app.
enum Advisor {
    static func reply(to question: String, catches: [CatchRecord]) -> String {
        let q = question.lowercased()

        let illegal = ["dynamite", "dinamita", "pampasabog", "blast fishing", "cyanide", "sianuro", "lason", "poison",
                       "fine mesh", "fine-mesh", "protected area", "sanctuary", "pawikan", "turtle", "dolphin", "shark fin"]
        if illegal.contains(where: q.contains) {
            return "I can't help with that. Blast, poison and fine-mesh fishing and catching protected species are illegal and destroy the fishing grounds you depend on. Your Municipal Agriculture Office or BFAR can tell you which gear and areas are allowed."
        }

        // Try to detect a species mentioned in the question.
        if let species = FAIR_DB.keys.first(where: { q.contains($0.lowercased()) }) {
            let f = FAIR_DB[species]!
            let trend = f.week >= 0 ? "up \(String(format: "%.1f", f.week))%" : "down \(String(format: "%.1f", abs(f.week)))%"
            return "Based on recent Palakaya transactions near you, \(species) is currently selling around ₱\(f.low)–₱\(f.high)/kg (average ₱\(f.mid)). Prices are \(trend) this week."
        }

        if q.contains("fresh") || q.contains("ice") || q.contains("yelo") || q.contains("sariwa") {
            return "Keep fish cold from the moment you buy it: pack it in crushed ice (about 1 kg of ice for every 1 kg of fish) in a covered cooler, keep it out of the sun, and sell or cook it within a day."
        }
        if q.contains("verified") || q.contains("verify") || q.contains("badge") {
            return "Go to Profile → Buyer Verification. Send a photo of your business permit, cooperative registration or a government ID to your Municipal Agriculture Office or the Palakaya team. The badge then shows on your profile and offers."
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

        if q.contains("value") || q.contains("cheap") || q.contains("mura") {
            if let low = FAIR_DB.min(by: { $0.value.mid < $1.value.mid }) {
                return "\(low.key) is the most affordable this week at around ₱\(low.value.mid)/kg (fair range ₱\(low.value.low)–₱\(low.value.high)). Offering within that range gets accepted most often."
            }
        }

        if q.contains("mataas") || q.contains("highest") || q.contains("linggo") || q.contains("week") {
            if let top = FAIR_DB.max(by: { $0.value.mid < $1.value.mid }) {
                return "\(top.key) has the highest average price this week at around ₱\(top.value.mid)/kg. Galunggong is also trending upward, up \(String(format: "%.1f", FAIR_DB["Galunggong"]?.week ?? 0))% this week."
            }
        }

        if q.contains("mababa") || q.contains("below") || q.contains("bakit") || q.contains("last sale") || q.contains("fair") {
            if let lastSale = catches.first(where: { $0.status == .sold }), let fair = lastSale.fair, let price = lastSale.price {
                if price < Double(fair.low) {
                    return "Your last sale of \(lastSale.species) was at ₱\(Int(price))/kg, which is below today's benchmark range of ₱\(fair.low)–₱\(fair.high)/kg. Try comparing offers from more buyers before accepting next time — the Buyer Matches screen shows nearby offers side by side."
                }
                return "Your last sale of \(lastSale.species) at ₱\(Int(price))/kg was actually within the fair range of ₱\(fair.low)–₱\(fair.high)/kg — nicely done."
            }
            return "I don't see a recorded sale yet to compare. Once you record a sale, I can tell you how it lined up with the local benchmark."
        }

        return "I can only help with fishing, your catch and fish prices. Try asking \"How much is Galunggong today?\", \"Which fishing ground gave me the most?\" or \"Was my last sale fair?\""
    }
}

/// Stores the conversation and gets the reply: from the AI Advisor (Supabase Edge Function `advisor`)
/// when cloud sync is on, otherwise from the offline rule-based `Advisor`.
@MainActor
struct AdvisorController {
    let context: ModelContext

    private struct Turn: Codable { let role: String; let text: String }
    private struct CatchSummary: Encodable {
        let species: String, kg: Double, ground: String, date: String, status: String
        let pricePerKg: Double?, saleAmount: Double?
    }
    private struct PriceSummary: Encodable { let low: Int, high: Int, source: String }
    private struct Context: Encodable {
        let role: String, municipality: String, province: String, landingSite: String, today: String
        let catches: [CatchSummary]
        let fairPrices: [String: PriceSummary]
    }
    private struct Request: Encodable { let question: String; let history: [Turn]; let context: Context }
    private struct Reply: Decodable { let reply: String? }

    func ask(_ question: String, catches: [CatchRecord], history: [AdvisorMessageRecord], appState: AppState) async throws {
        let ownerID = appState.currentUserID
        context.insert(AdvisorMessageRecord(isUser: true, text: question, ownerID: ownerID))
        try context.save()

        let answer = await aiReply(question, catches: catches, history: history, appState: appState)
            ?? Advisor.reply(to: question, catches: catches)
        context.insert(AdvisorMessageRecord(isUser: false, text: answer, ownerID: ownerID))
        try context.save()
    }

    /// Returns nil when the AI is unavailable (offline, not signed in, not deployed), so the offline advisor answers.
    private func aiReply(_ question: String, catches: [CatchRecord], history: [AdvisorMessageRecord],
                         appState: AppState) async -> String? {
        guard AppConfig.isCloudEnabled, SupabaseClient.shared.isSignedIn else { return nil }
        let day = Date.FormatStyle().year().month().day()
        let ctx = Context(
            role: appState.isBuyer ? "buyer" : "fisher", municipality: appState.currentUserMunicipality, province: appState.currentUserProvince,
            landingSite: appState.currentUserLandingSite, today: Date().formatted(day),
            catches: catches.sorted { $0.dateLogged > $1.dateLogged }.prefix(40).map {
                CatchSummary(species: $0.species, kg: $0.weight, ground: $0.ground, date: $0.dateLogged.formatted(day),
                             status: $0.statusRaw, pricePerKg: $0.price, saleAmount: $0.saleAmount)
            },
            fairPrices: FAIR_DB.mapValues {
                PriceSummary(low: $0.low, high: $0.high,
                             source: $0.saleCount.map { "\($0) recent sales" } ?? "estimate")
            })
        let turns = history.suffix(6).map { Turn(role: $0.isUser ? "user" : "assistant", text: $0.text) }
        do {
            let data = try await SupabaseClient.shared.invoke(function: "advisor",
                body: Request(question: question, history: turns, context: ctx))
            appState.isOffline = false
            return try JSONDecoder().decode(Reply.self, from: data).reply
        } catch {
            appState.isOffline = (error as? URLError) != nil
            return nil
        }
    }
}
