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
        var photo_url: String? = nil
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

    /// Uploads profile edits made in Profile. Does nothing when signed out; the next login uploads them.
    static func pushProfile(_ user: UserAccount) async throws {
        let client = SupabaseClient.shared
        guard AppConfig.isCloudEnabled, let id = client.userID else { return }
        try await client.upsert("profiles", rows: [ProfileRow(
            id: id, full_name: user.fullName, mobile: user.mobile, municipality: user.municipality,
            province: user.province, landing_site: user.landingSite, fisherfolk_id: user.fisherfolkID,
            role: user.role, business_name: user.businessName)])
    }

    /// Whether the admin has verified this account (buyers get a Verified badge).
    static func isVerified() async -> Bool {
        struct Row: Decodable { let verified: Bool }
        let rows: [Row]? = try? await SupabaseClient.shared.select("my_profile", query: "select=verified")
        return rows?.first?.verified ?? false
    }

    /// Uploads photos that are not online yet. A failed upload is retried on the next sync and never blocks the rest.
    private static func uploadPhotos(_ records: [CatchRecord]) async {
        guard let owner = SupabaseClient.shared.userID?.lowercased() else { return }
        for record in records where record.photoURL == nil {
            guard let data = record.photoData else { continue }
            let path = "\(owner)/\(record.id.uuidString.lowercased()).jpg"
            record.photoURL = try? await SupabaseClient.shared.uploadPublicJPEG(data, bucket: "catch-photos", path: path)
        }
    }

    private static let deletesKey = "pendingCatchDeletes"

    /// Catches deleted on this phone that the cloud still has. They are deleted there on the next sync
    /// and are never downloaded again in the meantime.
    static var pendingDeletes: Set<UUID> {
        get { Set((UserDefaults.standard.stringArray(forKey: deletesKey) ?? []).compactMap(UUID.init)) }
        set { UserDefaults.standard.set(newValue.map(\.uuidString), forKey: deletesKey) }
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
        let deleted = pendingDeletes
        for row in rows where !deleted.contains(row.id) {
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

        let samples = DemoController.sampleIDs
        let pending = try context.fetch(FetchDescriptor<CatchRecord>(predicate: #Predicate { $0.needsSync }))
            .filter { !samples.contains($0.id) }
        await uploadPhotos(pending)
        let rows = pending.map {
            CatchRow(id: $0.id, species: $0.species, weight_kg: $0.weight, fishing_ground: $0.ground,
                     caught_at: $0.dateLogged, status: $0.statusRaw, price_per_kg: $0.price,
                     sale_amount: $0.saleAmount, buyer_name: $0.buyerName, alignment_pct: $0.alignment,
                     photo_url: $0.photoURL)
        }
        do {
            try await SupabaseClient.shared.upsert("catches", rows: rows)
        } catch CloudError.server(let code, let message) where code == 400 && message.contains("photo_url") {
            // The database has not run migration 006 yet: upload without photos.
            try await SupabaseClient.shared.upsert("catches", rows: rows.map { var r = $0; r.photo_url = nil; return r })
        }
        pending.forEach { $0.needsSync = false }
        try context.save()
        for id in pendingDeletes {
            try await SupabaseClient.shared.delete("catches", id: id)
            pendingDeletes.remove(id)
        }
        return pending.count
    }
}
