import Foundation
import SwiftData

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
