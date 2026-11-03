import Foundation

/// Loads other fishers' listings from the cloud `market_listings` view.
@MainActor
enum MarketController {
    private struct ListingRow: Decodable {
        let id: UUID
        let species: String
        let weight_kg: Double
        let price_per_kg: Double
        let caught_at: Date
        let seller_first_name: String
        let landing_site: String?
        let municipality: String?
        let contact_mobile: String?
    }

    static func refresh(appState: AppState) async {
        guard AppConfig.isCloudEnabled, SupabaseClient.shared.isSignedIn else {
            appState.marketListings = SAMPLE_LISTINGS
            appState.marketIsSample = true
            return
        }
        do {
            let rows: [ListingRow] = try await SupabaseClient.shared.select("market_listings", query: "select=*&limit=100")
            appState.marketListings = rows.map(listing(from:))
            appState.marketIsSample = false
            appState.isOffline = false
        } catch {
            appState.isOffline = (error as? URLError) != nil
        }
    }

    private static func listing(from row: ListingRow) -> OtherListing {
        let price = Int(row.price_per_kg.rounded())
        let site = [row.landing_site, row.municipality].compactMap { $0 }.joined(separator: ", ")
        return OtherListing(
            id: row.id.uuidString, species: row.species, weight: row.weight_kg, price: price,
            seller: row.seller_first_name, rating: nil, site: site.isEmpty ? "Location not set" : site,
            distance: nil, fair: FAIR_DB[row.species].map { price >= $0.low } ?? true,
            fresh: Calendar.current.isDateInToday(row.caught_at), contactMobile: row.contact_mobile)
    }
}
