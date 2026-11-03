import Foundation
import SwiftData

enum CatchStatus: String, Codable {
    case available, listed, sold
}

@Model
final class CatchRecord {
    @Attribute(.unique) var id: UUID
    /// The UserAccount that logged this catch.
    var ownerID: UUID?
    var species: String
    var weight: Double
    var ground: String
    var timeLabel: String
    var dateLogged: Date
    var statusRaw: String
    var price: Double?
    var saleAmount: Double?
    var buyerName: String?
    var alignment: Int?
    var buyersInterested: Int?
    var hasPhoto: Bool
    /// JPEG of the catch, kept on the phone (stored outside the database file).
    @Attribute(.externalStorage) var photoData: Data?
    /// True until this record has been uploaded to the cloud.
    var needsSync: Bool = true

    init(species: String, weight: Double, ground: String, timeLabel: String, dateLogged: Date = Date(),
         status: CatchStatus = .available, price: Double? = nil, saleAmount: Double? = nil,
         buyerName: String? = nil, alignment: Int? = nil, buyersInterested: Int? = nil, hasPhoto: Bool = false) {
        self.id = UUID()
        self.species = species
        self.weight = weight
        self.ground = ground
        self.timeLabel = timeLabel
        self.dateLogged = dateLogged
        self.statusRaw = status.rawValue
        self.price = price
        self.saleAmount = saleAmount
        self.buyerName = buyerName
        self.alignment = alignment
        self.buyersInterested = buyersInterested
        self.hasPhoto = hasPhoto
    }

    var status: CatchStatus {
        get { CatchStatus(rawValue: statusRaw) ?? .available }
        set { statusRaw = newValue.rawValue }
    }

    var loggedLabel: String { "\(dateLogged.pkDayLabel) · \(timeLabel)" }

    var fair: FairPriceInfo? { FAIR_DB[species] }
}

extension Array where Element == CatchRecord {
    /// Only the catches that belong to the signed-in fisher.
    func owned(by userID: UUID?) -> [CatchRecord] {
        guard let userID else { return [] }
        return filter { $0.ownerID == userID }
    }
}
