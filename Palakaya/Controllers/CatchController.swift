import Foundation
import SwiftData

/// Business rules for catches, listings and sales. Views call this instead of touching the model context.
struct CatchController {
    let context: ModelContext

    @discardableResult
    func saveCatch(ownerID: UUID?, species: String, weight: Double, ground: String, date: Date, photo: Data?) throws -> CatchRecord {
        let record = CatchRecord(species: species, weight: weight, ground: ground,
                                 timeLabel: date.pkTimeLabel, dateLogged: date, hasPhoto: photo != nil)
        record.photoData = photo
        record.ownerID = ownerID
        context.insert(record)
        try context.save()
        return record
    }

    /// Saves edits to a catch that has not been sold. The time label follows the new date.
    func updateCatch(_ record: CatchRecord, species: String, weight: Double, ground: String, date: Date, photo: Data?) throws {
        record.species = species
        record.weight = weight
        record.ground = ground
        record.dateLogged = date
        record.timeLabel = date.pkTimeLabel
        record.photoData = photo
        record.hasPhoto = photo != nil
        record.needsSync = true
        try context.save()
    }

    /// Removes a catch from this phone and queues its removal from the cloud.
    @MainActor func deleteCatch(_ record: CatchRecord) throws {
        SyncService.pendingDeletes.insert(record.id)
        context.delete(record)
        try context.save()
    }

    func publishListing(_ record: CatchRecord, pricePerKg: Double) throws {
        record.status = .listed
        record.price = pricePerKg
        record.buyersInterested = 0
        record.needsSync = true
        try context.save()
    }

    /// Records the sale and returns the summary shown on the confirmation screen.
    /// `alignment` is nil when the species has no benchmark yet.
    func completeSale(_ record: CatchRecord, buyer: Buyer) throws -> SaleResult {
        let amount = Int((buyer.quantity ?? record.weight) * Double(buyer.offer))
        let alignment = record.fair.map { Int(Double(buyer.offer) / Double($0.mid) * 100) }
        record.status = .sold
        record.price = Double(buyer.offer)
        record.saleAmount = Double(amount)
        record.buyerName = buyer.name
        record.alignment = alignment
        record.needsSync = true
        try context.save()
        return SaleResult(amount: amount, alignment: alignment, buyerName: buyer.name, species: record.species)
    }
}
