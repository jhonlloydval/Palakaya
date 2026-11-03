import Foundation

enum OfferStatus: String, Codable {
    case pending, accepted, declined, paid, cancelled

    var label: String {
        switch self {
        case .pending: return "Waiting for fisher"
        case .accepted: return "Accepted · awaiting payment"
        case .declined: return "Declined"
        case .paid: return "Paid"
        case .cancelled: return "Cancelled"
        }
    }
}

/// A buyer's offer on a listed catch, as seen by either party (Supabase `my_offers` view).
struct Offer: Identifiable, Decodable, Hashable {
    let id: UUID
    let catchID: UUID
    let status: OfferStatus
    let pricePerKg: Double
    let quantityKg: Double
    let message: String
    let paymentMethod: String?
    let paymentRef: String?
    let paidAt: Date?
    let createdAt: Date
    let species: String
    let iAmBuyer: Bool
    let buyerName: String
    let buyerVerified: Bool
    let buyerMunicipality: String?
    let buyerMobile: String
    let buyerPaidCount: Int
    let fisherFirstName: String
    let fisherLandingSite: String?
    let fisherMobile: String

    enum CodingKeys: String, CodingKey {
        case id, status, message, species
        case catchID = "catch_id"
        case pricePerKg = "price_per_kg"
        case quantityKg = "quantity_kg"
        case paymentMethod = "payment_method"
        case paymentRef = "payment_ref"
        case paidAt = "paid_at"
        case createdAt = "created_at"
        case iAmBuyer = "i_am_buyer"
        case buyerName = "buyer_name"
        case buyerVerified = "buyer_verified"
        case buyerMunicipality = "buyer_municipality"
        case buyerMobile = "buyer_mobile"
        case buyerPaidCount = "buyer_paid_count"
        case fisherFirstName = "fisher_first_name"
        case fisherLandingSite = "fisher_landing_site"
        case fisherMobile = "fisher_mobile"
    }

    var total: Int { Int((pricePerKg * quantityKg).rounded()) }
}
