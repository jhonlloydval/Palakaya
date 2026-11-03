import Foundation

/// Fetches fair-price ranges computed from real recorded sales (Supabase `fair_prices` view).
enum FairPriceService {
    private(set) static var live: [String: FairPriceInfo] = [:]

    private struct Row: Decodable {
        let species: String
        let sale_count: Int
        let low: Double
        let mid: Double
        let high: Double
    }

    static func refresh() async {
        guard AppConfig.isCloudEnabled, SupabaseClient.shared.isSignedIn else { return }
        guard let rows: [Row] = try? await SupabaseClient.shared.select("fair_prices") else { return }
        live = Dictionary(uniqueKeysWithValues: rows.map { row in
            let estimate = ESTIMATED_FAIR_PRICES[row.species]
            return (row.species, FairPriceInfo(
                low: Int(row.low), high: Int(row.high), mid: Int(row.mid),
                week: estimate?.week ?? 0, history: estimate?.history ?? [Int(row.mid)],
                saleCount: row.sale_count))
        })
    }
}
