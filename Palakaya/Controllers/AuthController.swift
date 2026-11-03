import Foundation
import SwiftData

enum AuthError: LocalizedError {
    case missingFields
    case invalidMobile
    case accountExists
    case accountNotFound
    case wrongPassword
    case storageFailed

    var errorDescription: String? {
        switch self {
        case .missingFields: return "Please fill in your name, mobile number, and password."
        case .invalidMobile: return "Enter a valid 11-digit mobile number (09XX XXX XXXX)."
        case .accountExists: return "An account with that mobile number already exists."
        case .accountNotFound: return "No account found for that mobile number."
        case .wrongPassword: return "Incorrect password."
        case .storageFailed: return "Could not save your account. Please try again."
        }
    }
}

/// Login and registration rules. Views only collect input and show the resulting error.
struct AuthController {
    let context: ModelContext

    func login(mobile rawMobile: String, password: String) throws -> UserAccount {
        let mobile = InputParsing.normalizedMobile(rawMobile)
        guard let user = try findUser(mobile: mobile) else { throw AuthError.accountNotFound }
        guard user.verifyPassword(password) else { throw AuthError.wrongPassword }
        return user
    }

    func register(name: String, mobile rawMobile: String, municipality: String, province: String,
                  landingSite: String, fisherfolkID: String, password: String) throws -> UserAccount {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty,
              !rawMobile.trimmingCharacters(in: .whitespaces).isEmpty,
              !password.isEmpty else { throw AuthError.missingFields }
        guard InputParsing.isValidMobile(rawMobile) else { throw AuthError.invalidMobile }
        let mobile = InputParsing.normalizedMobile(rawMobile)
        guard try findUser(mobile: mobile) == nil else { throw AuthError.accountExists }

        let user = UserAccount(fullName: name, mobile: mobile, password: password, municipality: municipality,
                               province: province, landingSite: landingSite, fisherfolkID: fisherfolkID)
        context.insert(user)
        let firstName = user.fullName.split(separator: " ").first.map(String.init) ?? "there"
        context.insert(AdvisorMessageRecord(isUser: false, text: "Kamusta, \(firstName). Ano ang gusto mong malaman?", ownerID: user.id))
        do { try context.save() } catch { throw AuthError.storageFailed }
        return user
    }

    private func findUser(mobile: String) throws -> UserAccount? {
        let descriptor = FetchDescriptor<UserAccount>(predicate: #Predicate { $0.mobile == mobile })
        return try context.fetch(descriptor).first
    }
}
