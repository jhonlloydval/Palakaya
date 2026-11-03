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

    /// The name to greet someone by, skipping honorifics: "Mang Jose Dela Cruz" → "Jose".
    static func firstName(_ fullName: String) -> String {
        let honorifics: Set<String> = ["mang", "aling", "ka", "kuya", "ate", "manong", "manang", "mr.", "mrs.", "ms.", "mr", "mrs", "ms"]
        let parts = fullName.split(separator: " ").map(String.init)
        return parts.first { !honorifics.contains($0.lowercased()) } ?? parts.first ?? ""
    }

    /// Password rules shown on the sign-up form: at least 8 characters with an uppercase letter,
    /// a lowercase letter and a number (e.g. "Kahitano1Jl").
    static let passwordRules: [(label: String, check: (String) -> Bool)] = [
        ("At least 8 characters", { $0.count >= 8 }),
        ("An uppercase letter (A–Z)", { $0.contains(where: \.isUppercase) }),
        ("A lowercase letter (a–z)", { $0.contains(where: \.isLowercase) }),
        ("A number (0–9)", { $0.contains(where: \.isNumber) }),
    ]

    static func isStrongPassword(_ password: String) -> Bool {
        passwordRules.allSatisfy { $0.check(password) }
    }

    /// Accepts "8.5" and "8,5". Returns nil unless the weight is within a sane per-catch range.
    static func weightKg(_ raw: String) -> Double? {
        let cleaned = raw.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")
        guard let value = Double(cleaned), value > 0, value <= 5000 else { return nil }
        return value
    }
}
