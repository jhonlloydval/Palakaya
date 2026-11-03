import Foundation
import SwiftData

/// Uploads local records to Supabase. SwiftData stays the source of truth on the phone,
/// so logging works offline and pending records upload the next time there is signal.
@MainActor
enum SyncService {
    private struct ProfileRow: Encodable {
        let id: String
        let full_name, mobile, municipality, province, landing_site, fisherfolk_id, role, business_name: String
    }

    private struct CatchRow: Codable {
        let id: UUID
        let species: String
        let weight_kg: Double
        let fishing_ground: String
        let caught_at: Date
        let status: String
        let price_per_kg: Double?
        let sale_amount: Double?
        let buyer_name: String?
        let alignment_pct: Int?
    }

    /// Signs in to the cloud, creating the cloud account the first time. Local login has already succeeded.
    static func connect(user: UserAccount, password: String) async throws {
        guard AppConfig.isCloudEnabled else { throw CloudError.notConfigured }
        let client = SupabaseClient.shared
        do {
            try await client.signIn(mobile: user.mobile, password: password)
        } catch CloudError.server(400, _) {
            try await client.signUp(mobile: user.mobile, password: password)
        }
        guard let id = client.userID else { throw CloudError.notSignedIn }
        try await client.upsert("profiles", rows: [ProfileRow(
            id: id, full_name: user.fullName, mobile: user.mobile, municipality: user.municipality,
            province: user.province, landing_site: user.landingSite, fisherfolk_id: user.fisherfolkID,
            role: user.role, business_name: user.businessName)])
    }

    /// Downloads this account's catches so a reinstall or new phone gets them back.
    /// Local edits that have not uploaded yet win over the cloud copy.
    @discardableResult
    static func pull(ownerID: UUID, context: ModelContext) async throws -> Int {
        guard AppConfig.isCloudEnabled else { throw CloudError.notConfigured }
        let rows: [CatchRow] = try await SupabaseClient.shared.select("catches",
            query: "select=id,species,weight_kg,fishing_ground,caught_at,status,price_per_kg,sale_amount,buyer_name,alignment_pct")
        let local = try context.fetch(FetchDescriptor<CatchRecord>())
        let byID = Dictionary(local.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })

        var added = 0
        for row in rows {
            let record: CatchRecord
            if let existing = byID[row.id] {
                guard !existing.needsSync else { continue }
                record = existing
            } else {
                record = CatchRecord(species: row.species, weight: row.weight_kg, ground: row.fishing_ground,
                                     timeLabel: row.caught_at.pkTimeLabel, dateLogged: row.caught_at)
                record.id = row.id
                context.insert(record)
                added += 1
            }
            record.ownerID = ownerID
            record.statusRaw = row.status
            record.price = row.price_per_kg
            record.saleAmount = row.sale_amount
            record.buyerName = row.buyer_name
            record.alignment = row.alignment_pct
            record.needsSync = false
        }
        try context.save()
        return added
    }

    /// Uploads every record marked `needsSync`. Returns how many were uploaded.
    @discardableResult
    static func pushPending(context: ModelContext) async throws -> Int {
        guard AppConfig.isCloudEnabled else { throw CloudError.notConfigured }
        guard SupabaseClient.shared.isSignedIn else { throw CloudError.notSignedIn }

        let pending = try context.fetch(FetchDescriptor<CatchRecord>(predicate: #Predicate { $0.needsSync }))
        let rows = pending.map {
            CatchRow(id: $0.id, species: $0.species, weight_kg: $0.weight, fishing_ground: $0.ground,
                     caught_at: $0.dateLogged, status: $0.statusRaw, price_per_kg: $0.price,
                     sale_amount: $0.saleAmount, buyer_name: $0.buyerName, alignment_pct: $0.alignment)
        }
        try await SupabaseClient.shared.upsert("catches", rows: rows)
        pending.forEach { $0.needsSync = false }
        try context.save()
        return pending.count
    }
}
