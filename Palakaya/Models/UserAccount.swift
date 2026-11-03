import Foundation
import SwiftData

@Model
final class UserAccount {
    @Attribute(.unique) var id: UUID
    var fullName: String
    var mobile: String
    @Attribute(originalName: "password") var passwordHash: String
    var municipality: String
    var province: String
    var landingSite: String
    var fisherfolkID: String
    var createdAt: Date

    init(fullName: String, mobile: String, password: String, municipality: String, province: String, landingSite: String, fisherfolkID: String) {
        self.id = UUID()
        self.fullName = fullName
        self.mobile = mobile
        self.passwordHash = PasswordHasher.hash(password, salt: mobile)
        self.municipality = municipality
        self.province = province
        self.landingSite = landingSite
        self.fisherfolkID = fisherfolkID
        self.createdAt = Date()
    }

    func verifyPassword(_ attempt: String) -> Bool {
        passwordHash == PasswordHasher.hash(attempt, salt: mobile)
    }

    var initials: String {
        let parts = fullName.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first }
        return String(letters).uppercased()
    }
}
