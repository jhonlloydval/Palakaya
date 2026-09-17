import Foundation
import SwiftData

enum CatchStatus: String, Codable {
    case available, listed, sold
}

@Model
final class UserAccount {
    @Attribute(.unique) var id: UUID
    var fullName: String
    var mobile: String
    var password: String
    var municipality: String
    var province: String
    var landingSite: String
    var fisherfolkID: String
    var createdAt: Date

    init(fullName: String, mobile: String, password: String, municipality: String, province: String, landingSite: String, fisherfolkID: String) {
        self.id = UUID()
        self.fullName = fullName
        self.mobile = mobile
        self.password = password
        self.municipality = municipality
        self.province = province
        self.landingSite = landingSite
        self.fisherfolkID = fisherfolkID
        self.createdAt = Date()
    }

    var initials: String {
        let parts = fullName.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first }
        return String(letters).uppercased()
    }
}

@Model
final class CatchRecord {
    @Attribute(.unique) var id: UUID
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

    init(species: String, weight: Double, ground: String, timeLabel: String,
         status: CatchStatus = .available, price: Double? = nil, saleAmount: Double? = nil,
         buyerName: String? = nil, alignment: Int? = nil, buyersInterested: Int? = nil, hasPhoto: Bool = false) {
        self.id = UUID()
        self.species = species
        self.weight = weight
        self.ground = ground
        self.timeLabel = timeLabel
        self.dateLogged = Date()
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

    var fair: FairPriceInfo? { FAIR_DB[species] }
}

@Model
final class AdvisorMessageRecord {
    @Attribute(.unique) var id: UUID
    var isUser: Bool
    var text: String
    var timestamp: Date

    init(isUser: Bool, text: String) {
        self.id = UUID()
        self.isUser = isUser
        self.text = text
        self.timestamp = Date()
    }
}
