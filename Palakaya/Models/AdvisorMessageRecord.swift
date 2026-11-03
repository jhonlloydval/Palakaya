import Foundation
import SwiftData

@Model
final class AdvisorMessageRecord {
    @Attribute(.unique) var id: UUID
    var ownerID: UUID?
    var isUser: Bool
    var text: String
    var timestamp: Date

    init(isUser: Bool, text: String, ownerID: UUID? = nil) {
        self.id = UUID()
        self.ownerID = ownerID
        self.isUser = isUser
        self.text = text
        self.timestamp = Date()
    }
}
