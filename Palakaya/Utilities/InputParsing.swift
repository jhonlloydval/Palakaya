import Foundation

enum InputParsing {
    /// Keeps digits only so "0917 234 5678" and "09172345678" are the same account.
    static func normalizedMobile(_ raw: String) -> String {
        var digits = raw.filter(\.isNumber)
        if digits.hasPrefix("63") && digits.count == 12 { digits = "0" + digits.dropFirst(2) }
        return digits
    }

    static func isValidMobile(_ raw: String) -> Bool {
        let m = normalizedMobile(raw)
        return m.count == 11 && m.hasPrefix("09")
    }

    /// Accepts "8.5" and "8,5". Returns nil unless the weight is within a sane per-catch range.
    static func weightKg(_ raw: String) -> Double? {
        let cleaned = raw.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")
        guard let value = Double(cleaned), value > 0, value <= 5000 else { return nil }
        return value
    }
}
