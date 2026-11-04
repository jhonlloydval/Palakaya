import Foundation
import SwiftData

enum AuthError: LocalizedError {
    case missingFields
    case missingBusiness
    case invalidMobile
    case weakPassword
    case accountExists
    case accountNotFound
    case wrongPassword
    case storageFailed

    var errorDescription: String? {
        switch self {
        case .missingFields: return "Please fill in your name, mobile number, and password."
        case .missingBusiness: return "Please enter your store, stall or cooperative name."
        case .invalidMobile: return "Enter a valid 11-digit mobile number (09XX XXX XXXX)."
        case .weakPassword: return "Your password needs at least 8 characters, with an uppercase letter, a lowercase letter and a number."
        case .accountExists: return "An account with that mobile number already exists."
        case .accountNotFound: return "No account found for that mobile number."
        case .wrongPassword: return "Incorrect password."
        case .storageFailed: return "Could not save your account. Please try again."
        }
    }
}

/// Login and registration rules. Views only collect input and show the resulting error.
@MainActor
struct AuthController {
    let context: ModelContext

    /// Logs in with the account on this phone, or restores it from the cloud on a new phone.
    func login(mobile rawMobile: String, password: String) async throws -> UserAccount {
        let mobile = InputParsing.normalizedMobile(rawMobile)
        if let user = try findUser(mobile: mobile) {
            guard user.verifyPassword(password) else { throw AuthError.wrongPassword }
            return user
        }
        guard AppConfig.isCloudEnabled else { throw AuthError.accountNotFound }
        return try await restoreFromCloud(mobile: mobile, password: password)
    }

    private struct CloudProfile: Decodable {
        let full_name, mobile, municipality, province, landing_site, fisherfolk_id, role, business_name: String
    }

    private func restoreFromCloud(mobile: String, password: String) async throws -> UserAccount {
        do {
            try await SupabaseClient.shared.signIn(mobile: mobile, password: password)
        } catch CloudError.server(400, _) {
            throw AuthError.accountNotFound
        } catch {
            throw AuthError.accountNotFound
        }
        guard let p: CloudProfile = try? await SupabaseClient.shared.select("my_profile").first else {
            throw AuthError.accountNotFound
        }
        let user = UserAccount(fullName: p.full_name, mobile: mobile, password: password, municipality: p.municipality,
                               province: p.province, landingSite: p.landing_site, fisherfolkID: p.fisherfolk_id,
                               role: p.role, businessName: p.business_name)
        context.insert(user)
        context.insert(AdvisorMessageRecord(isUser: false, text: welcome(for: user), ownerID: user.id))
        do { try context.save() } catch { throw AuthError.storageFailed }
        return user
    }

    func register(name: String, mobile rawMobile: String, municipality: String, province: String,
                  landingSite: String, fisherfolkID: String, password: String,
                  role: String = "fisher", businessName: String = "") throws -> UserAccount {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty,
              !rawMobile.trimmingCharacters(in: .whitespaces).isEmpty,
              !password.isEmpty else { throw AuthError.missingFields }
        if role == "buyer" && businessName.trimmingCharacters(in: .whitespaces).isEmpty {
            throw AuthError.missingBusiness
        }
        guard InputParsing.isValidMobile(rawMobile) else { throw AuthError.invalidMobile }
        guard InputParsing.isStrongPassword(password) else { throw AuthError.weakPassword }
        let mobile = InputParsing.normalizedMobile(rawMobile)
        guard try findUser(mobile: mobile) == nil else { throw AuthError.accountExists }

        let user = UserAccount(fullName: name, mobile: mobile, password: password, municipality: municipality,
                               province: province, landingSite: role == "buyer" ? "" : landingSite,
                               fisherfolkID: role == "buyer" ? "" : fisherfolkID,
                               role: role, businessName: businessName.trimmingCharacters(in: .whitespaces))
        context.insert(user)
        context.insert(AdvisorMessageRecord(isUser: false, text: welcome(for: user), ownerID: user.id))
        do { try context.save() } catch { throw AuthError.storageFailed }
        return user
    }

    /// Saves edits from Profile. The mobile number stays fixed because it is the login.
    func updateProfile(_ user: UserAccount, name: String, municipality: String, province: String,
                       landingSite: String, fisherfolkID: String) throws {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { throw AuthError.missingFields }
        user.fullName = trimmedName
        user.municipality = municipality.trimmingCharacters(in: .whitespaces)
        user.province = province.trimmingCharacters(in: .whitespaces)
        user.landingSite = landingSite.trimmingCharacters(in: .whitespaces)
        user.fisherfolkID = fisherfolkID.trimmingCharacters(in: .whitespaces)
        do { try context.save() } catch { throw AuthError.storageFailed }
    }

    /// Changes the password on this phone and, when signed in, in the cloud account too.
    func changePassword(_ user: UserAccount, current: String, new: String) async throws {
        guard user.verifyPassword(current) else { throw AuthError.wrongPassword }
        guard InputParsing.isStrongPassword(new) else { throw AuthError.weakPassword }
        if AppConfig.isCloudEnabled, SupabaseClient.shared.isSignedIn {
            try await SupabaseClient.shared.updatePassword(new)
        }
        user.passwordHash = PasswordHasher.hash(new, salt: user.mobile)
        do { try context.save() } catch { throw AuthError.storageFailed }
    }

    private func welcome(for user: UserAccount) -> String {
        let firstName = InputParsing.firstName(user.fullName).isEmpty ? "there" : InputParsing.firstName(user.fullName)
        return "Hi \(firstName)! Ask me about your catch, fish prices or selling. You can write in English or Filipino."
    }

    private func findUser(mobile: String) throws -> UserAccount? {
        let descriptor = FetchDescriptor<UserAccount>(predicate: #Predicate { $0.mobile == mobile })
        return try context.fetch(descriptor).first
    }
}
