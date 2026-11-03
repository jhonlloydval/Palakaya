import Foundation
import SwiftData

/// Business rules for catches, listings and sales. Views call this instead of touching the model context.
struct CatchController {
    let context: ModelContext

    @discardableResult
    func saveCatch(species: String, weight: Double, ground: String, date: Date, hasPhoto: Bool) throws -> CatchRecord {
        let record = CatchRecord(species: species, weight: weight, ground: ground,
                                 timeLabel: date.pkTimeLabel, dateLogged: date, hasPhoto: hasPhoto)
        context.insert(record)
        try context.save()
        return record
    }

    func publishListing(_ record: CatchRecord, pricePerKg: Double) throws {
        record.status = .listed
        record.price = pricePerKg
        record.buyersInterested = BUYERS.count
        try context.save()
    }

    /// Records the sale and returns the summary shown on the confirmation screen.
    /// `alignment` is nil when the species has no benchmark yet.
    func completeSale(_ record: CatchRecord, buyer: Buyer) throws -> SaleResult {
        let amount = Int(record.weight * Double(buyer.offer))
        let alignment = record.fair.map { Int(Double(buyer.offer) / Double($0.mid) * 100) }
        record.status = .sold
        record.price = Double(buyer.offer)
        record.saleAmount = Double(amount)
        record.buyerName = buyer.name
        record.alignment = alignment
        try context.save()
        return SaleResult(amount: amount, alignment: alignment, buyerName: buyer.name, species: record.species)
    }
}
