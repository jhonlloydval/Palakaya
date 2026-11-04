import SwiftUI

/// Payment channels offered in the demo checkout. No real account is ever contacted.
enum PaymentMethod: String, CaseIterable, Identifiable {
    case gcash, maya, landbank

    var id: String { rawValue }

    var name: String {
        switch self {
        case .gcash: return "GCash"
        case .maya: return "Maya"
        case .landbank: return "LandBank"
        }
    }

    var subtitle: String {
        switch self {
        case .gcash, .maya: return "E-wallet · pay with your mobile number"
        case .landbank: return "Online banking · pay from your account"
        }
    }

    var color: Color {
        switch self {
        case .gcash: return Color(hex: "007DFE")
        case .maya: return Color(hex: "00A651")
        case .landbank: return Color(hex: "00843D")
        }
    }

    var symbol: String {
        switch self {
        case .gcash, .maya: return "iphone"
        case .landbank: return "building.columns.fill"
        }
    }

    var isWallet: Bool { self != .landbank }

    /// What the payer types to identify their account.
    var accountLabel: String { isWallet ? "\(name) mobile number" : "LandBank account number" }
    var accountPlaceholder: String { isWallet ? "09XX XXX XXXX" : "10-digit account number" }
    /// The secret step after the one-time code: a 4-digit MPIN for wallets, a 6-digit online PIN for the bank.
    var pinLabel: String { isWallet ? "4-digit MPIN" : "6-digit online banking PIN" }
    var pinLength: Int { isWallet ? 4 : 6 }
}
