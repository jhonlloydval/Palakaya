import CryptoKit
import Foundation

enum PasswordHasher {
    /// Salted SHA-256, so the app never stores or compares a plain-text password.
    /// Local-only stopgap; real accounts should use the cloud auth provider instead.
    static func hash(_ password: String, salt: String) -> String {
        let digest = SHA256.hash(data: Data((salt + password).utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
