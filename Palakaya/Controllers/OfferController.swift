import Foundation

enum OfferError: LocalizedError {
    case needsCloud
    case server(String)

    var errorDescription: String? {
        switch self {
        case .needsCloud: return "Offers need an internet connection and a signed-in cloud account."
        case .server(let message): return message
        }
    }
}

/// Buyer offers: make an offer, accept or decline it (fisher), and pay for it (buyer, demo payment).
@MainActor
enum OfferController {
    private struct NewOffer: Encodable {
        let catch_id: UUID
        let price_per_kg: Double
        let quantity_kg: Double
        let message: String
    }
    private struct StatusChange: Encodable { let status: String }
    private struct Payment: Encodable { let status: String; let payment_method: String; let payment_ref: String }

    static var isAvailable: Bool { AppConfig.isCloudEnabled && SupabaseClient.shared.isSignedIn }

    /// Reloads every offer the signed-in user is part of.
    static func refresh(appState: AppState) async {
        guard isAvailable else { return }
        do {
            appState.myOffers = try await SupabaseClient.shared.select("my_offers", query: "select=*&limit=200")
            appState.isOffline = false
        } catch {
            appState.isOffline = (error as? URLError) != nil
        }
    }

    static func makeOffer(catchID: UUID, pricePerKg: Double, quantityKg: Double, message: String,
                          appState: AppState) async throws {
        try await run {
            try await SupabaseClient.shared.insert("offers", row: NewOffer(
                catch_id: catchID, price_per_kg: pricePerKg, quantity_kg: quantityKg,
                message: message.trimmingCharacters(in: .whitespacesAndNewlines)))
        }
        await refresh(appState: appState)
    }

    static func respond(to offer: Offer, accept: Bool, appState: AppState) async throws {
        try await run {
            try await SupabaseClient.shared.update("offers", filter: "id=eq.\(offer.id.uuidString)",
                                                   values: StatusChange(status: accept ? "accepted" : "declined"))
        }
        await refresh(appState: appState)
    }

    static func cancel(_ offer: Offer, appState: AppState) async throws {
        try await run {
            try await SupabaseClient.shared.update("offers", filter: "id=eq.\(offer.id.uuidString)",
                                                   values: StatusChange(status: "cancelled"))
        }
        await refresh(appState: appState)
    }

    /// Records a completed (demo) payment for an accepted offer.
    static func markPaid(_ offer: Offer, method: String, reference: String, appState: AppState) async throws {
        try await run {
            try await SupabaseClient.shared.update("offers", filter: "id=eq.\(offer.id.uuidString)",
                                                   values: Payment(status: "paid", payment_method: method, payment_ref: reference))
        }
        await refresh(appState: appState)
    }

    /// Offers waiting on one of the fisher's own catches.
    static func pendingOffers(for catchID: UUID, in offers: [Offer]) -> [Offer] {
        offers.filter { $0.catchID == catchID && !$0.iAmBuyer && $0.status == .pending }
            .sorted { $0.pricePerKg > $1.pricePerKg }
    }

    private static func run(_ work: () async throws -> Void) async throws {
        guard isAvailable else { throw OfferError.needsCloud }
        do {
            try await work()
        } catch CloudError.server(_, let body) {
            // Postgres errors from our triggers come back as {"message": "..."}; show that text.
            let message = (try? JSONSerialization.jsonObject(with: Data(body.utf8)) as? [String: Any])?["message"] as? String
            throw OfferError.server(message ?? "The offer could not be saved. Please try again.")
        } catch let error as URLError {
            throw OfferError.server(error.localizedDescription)
        }
    }
}
