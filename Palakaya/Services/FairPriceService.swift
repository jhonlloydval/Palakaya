import Foundation

/// Fetches fair-price ranges computed from real recorded sales: nationwide (Supabase `fair_prices`)
/// and per province (`regional_fair_prices`, migration 005).
enum FairPriceService {
    private(set) static var live: [String: FairPriceInfo] = [:]
    /// province → species → price range, only where the province has at least 5 recent sales.
    private(set) static var regional: [String: [String: FairPriceInfo]] = [:]
    private(set) static var lastRefresh: Date?
    /// The signed-in fisher's province, so prices around the app use their own area when it has data.
    static var homeProvince = ""

    private struct Row: Decodable {
        let species: String
        let sale_count: Int
        let low: Double
        let mid: Double
        let high: Double
    }

    private struct RegionalRow: Decodable {
        let province: String
        let species: String
        let sale_count: Int
        let low: Double
        let mid: Double
        let high: Double
    }

    static func refresh() async {
        guard AppConfig.isCloudEnabled, SupabaseClient.shared.isSignedIn else { return }
        if let rows: [Row] = try? await SupabaseClient.shared.select("fair_prices") {
            live = Dictionary(uniqueKeysWithValues: rows.map {
                ($0.species, info(species: $0.species, low: $0.low, mid: $0.mid, high: $0.high, count: $0.sale_count))
            })
            lastRefresh = Date()
        }
        // Older databases may not have run migration 005 yet; then only nationwide prices are shown.
        if let rows: [RegionalRow] = try? await SupabaseClient.shared.select("regional_fair_prices") {
            regional = Dictionary(grouping: rows, by: \.province).mapValues { group in
                Dictionary(uniqueKeysWithValues: group.map {
                    ($0.species, info(species: $0.species, low: $0.low, mid: $0.mid, high: $0.high, count: $0.sale_count))
                })
            }
        }
    }

    /// Provinces that have their own fair prices, by name ("Quezon").
    static var provincesWithData: [String] { Set(regional.keys.map(provinceName)).sorted() }

    /// Profiles store the province as typed ("Quezon, CALABARZON"), so match on the province name only.
    static func regionalKey(matching province: String) -> String? {
        let name = provinceName(province).lowercased()
        return regional.keys.first { provinceName($0).lowercased() == name }
    }

    private static func info(species: String, low: Double, mid: Double, high: Double, count: Int) -> FairPriceInfo {
        let estimate = ESTIMATED_FAIR_PRICES[species]
        return FairPriceInfo(low: Int(low), high: Int(high), mid: Int(mid),
                             week: estimate?.week ?? 0, history: estimate?.history ?? [Int(mid)], saleCount: count)
    }
}

/// Where a fair price came from, so the screen can say how much to trust it.
enum FairPriceSource {
    case province(String, sales: Int)
    case nationwide(sales: Int)
    case estimate

    var explanation: String {
        switch self {
        case .province(let name, let sales):
            return "From \(sales) sales recorded in \(name) in the last 30 days."
        case .nationwide(let sales):
            return "From \(sales) sales recorded across Palakaya in the last 30 days."
        case .estimate:
            return "Estimate from regional market averages. It switches to real prices once at least 5 sales are recorded."
        }
    }

    var isRegional: Bool {
        if case .province = self { return true }
        return false
    }

    var confidence: String {
        switch self {
        case .province(_, let sales), .nationwide(let sales): return sales >= 20 ? "High" : "Medium"
        case .estimate: return "Low (estimate)"
        }
    }
}

/// The best available price for a species in a province: that province's sales, then all sales, then the estimate.
func fairPrice(for species: String, province: String?) -> (info: FairPriceInfo, source: FairPriceSource)? {
    if let province, let key = FairPriceService.regionalKey(matching: province),
       let p = FairPriceService.regional[key]?[species], let n = p.saleCount {
        return (p, .province(provinceName(province), sales: n))
    }
    if let p = FairPriceService.live[species], let n = p.saleCount {
        return (p, .nationwide(sales: n))
    }
    if let p = ESTIMATED_FAIR_PRICES[species] { return (p, .estimate) }
    return nil
}

/// "Quezon, CALABARZON" → "Quezon".
func provinceName(_ raw: String) -> String {
    raw.split(separator: ",").first.map { $0.trimmingCharacters(in: .whitespaces) } ?? raw
}

/// Coastal provinces offered in the Fair Prices location picker, besides any that already have sales.
let COASTAL_PROVINCES = [
    "Aurora", "Batangas", "Bohol", "Cagayan", "Camarines Sur", "Capiz", "Cavite", "Cebu", "Iloilo",
    "La Union", "Leyte", "Masbate", "Mindoro Occidental", "Mindoro Oriental", "Negros Occidental",
    "Palawan", "Pangasinan", "Quezon", "Samar", "Sorsogon", "Surigao del Norte", "Zambales",
    "Zamboanga del Sur", "Davao del Sur", "General Santos (South Cotabato)",
]
