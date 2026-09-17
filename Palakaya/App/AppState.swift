import Foundation
import SwiftUI
import Observation

enum AppPhase {
    case onboarding, login, register, main
}

enum AppTab: String {
    case home, catchTab, market, advisor, profile
}

enum Route: Hashable {
    case catchDetails(UUID)
    case createListing(UUID)
    case listingDetails(UUID)
    case otherListingDetails(String)
    case buyerMatches(UUID)
    case recordSale(UUID)
    case saleRecorded
    case priceExplorer
    case reports
}

struct SaleResult {
    var amount: Int
    var alignment: Int
    var buyerName: String
    var species: String
}

@Observable
final class AppState {
    // Session
    var phase: AppPhase = .onboarding
    var obStep = 0
    var tab: AppTab = .home
    var path = NavigationPath()

    // Current signed-in user (denormalized for easy display; source of truth is UserAccount)
    var currentUserID: UUID?
    var currentUserName: String = ""
    var currentUserMunicipality: String = ""
    var currentUserProvince: String = ""
    var currentUserLandingSite: String = ""
    var currentUserFID: String = ""
    var currentUserMobile: String = ""

    // Login form
    var loginMobile: String = "0917 234 5678"
    var loginPassword: String = "password"
    var loginError: String?

    // Register form
    var regName = ""
    var regMobile = ""
    var regMunicipality = ""
    var regProvince = ""
    var regLanding = ""
    var regFID = ""
    var regPassword = ""
    var registerError: String?

    // Misc UI
    var isOffline = false
    var showNotifs = false
    var historyFilter = "All"

    // Log Catch flow
    var showLogCatch = false
    var lcStep = 1
    var lcSpecies: String?
    var lcWeight: String = ""
    var lcGround: String = "Sabang Fishing Ground"
    var lcPhoto = false

    // Active records / flows
    var activeCatchID: UUID?
    var listPrice: String = ""
    var listingQty: String = ""
    var listingLocation: String = "Sabang Landing Site, Batangas"
    var listingPickup: String = "Today, after 3:00 PM"
    var listingNotes: String = ""
    var selectedBuyer: Buyer?
    var saleResult: SaleResult?
    var priceSel: String = "Galunggong"

    // Advisor
    var advisorSuggestionsUsed: Set<Int> = []

    func resetLogCatch() {
        lcStep = 1
        lcSpecies = nil
        lcWeight = ""
        lcGround = "Sabang Fishing Ground"
        lcPhoto = false
    }

    func openLogCatch() {
        resetLogCatch()
        showLogCatch = true
    }

    func goTab(_ t: AppTab) {
        tab = t
        path = NavigationPath()
    }

    func logout() {
        phase = .onboarding
        obStep = 0
        tab = .home
        path = NavigationPath()
        currentUserID = nil
        currentUserName = ""
    }

    func applyUser(_ user: UserAccount) {
        currentUserID = user.id
        currentUserName = user.fullName
        currentUserMunicipality = user.municipality
        currentUserProvince = user.province
        currentUserLandingSite = user.landingSite.isEmpty ? "Sabang Landing Site" : user.landingSite
        currentUserFID = user.fisherfolkID
        currentUserMobile = user.mobile
        listingLocation = "\(currentUserLandingSite)\(currentUserProvince.isEmpty ? "" : ", \(currentUserProvince)")"
    }

    var userInitials: String {
        let parts = currentUserName.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first }
        return letters.isEmpty ? "JD" : String(letters).uppercased()
    }
}
