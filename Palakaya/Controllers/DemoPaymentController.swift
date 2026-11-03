import Foundation

/// Rules for the demonstration checkout. It follows the steps of a real e-wallet or bank payment
/// (account → one-time code → PIN → confirm) but never contacts any payment provider or moves money.
enum DemoPaymentController {
    /// The one-time code every demo payment accepts; shown on the code screen.
    static let demoOTP = "123456"

    static func isValidAccount(_ raw: String, for method: PaymentMethod) -> Bool {
        if method.isWallet { return InputParsing.isValidMobile(raw) }
        let digits = raw.filter(\.isNumber)
        return digits.count == 10 && digits == raw.replacingOccurrences(of: " ", with: "")
    }

    static func isValidOTP(_ code: String) -> Bool { code == demoOTP }

    static func isValidPIN(_ pin: String, for method: PaymentMethod) -> Bool {
        pin.count == method.pinLength && pin.allSatisfy(\.isNumber)
    }

    /// Masks an account for display, e.g. "0917 *** 5678" or "****** 4321".
    static func masked(_ raw: String, for method: PaymentMethod) -> String {
        let digits = raw.filter(\.isNumber)
        guard digits.count >= 4 else { return digits }
        if method.isWallet, digits.count == 11 {
            return "\(digits.prefix(4)) *** \(digits.suffix(4))"
        }
        return "****** \(digits.suffix(4))"
    }

    /// A reference number in the style each channel prints on its receipts.
    static func makeReference(for method: PaymentMethod) -> String {
        func digits(_ n: Int) -> String { (0..<n).map { _ in String(Int.random(in: 0...9)) }.joined() }
        switch method {
        case .gcash: return digits(13)
        case .maya: return digits(12)
        case .landbank: return "LBP" + digits(10)
        }
    }
}
