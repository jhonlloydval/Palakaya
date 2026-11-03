import Foundation
import SwiftUI
import Observation

enum AppPhase {
    case onboarding, login, register, main
}

enum AppTab: String {
    case home, catchTab, market, advisor, profile, offers
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
    case profileInfo(ProfileSection)
}

struct SaleResult {
    var amount: Int
    var alignment: Int?
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
    var currentUserRole: String = "fisher"
    var currentBusinessName: String = ""
    var isBuyer: Bool { currentUserRole == "buyer" }
    /// Set by the admin in the cloud after checking a buyer's permit or ID.
    var currentUserVerified = false

    // Login form
    var loginMobile: String = ""
    var loginPassword: String = ""
    var loginError: String?

    // Register form
    var regName = ""
    var regMobile = ""
    var regMunicipality = ""
    var regProvince = ""
    var regLanding = ""
    var regFID = ""
    var regPassword = ""
    var regRole = "fisher"
    var regBusiness = ""
    var registerError: String?

    // Misc UI
    var isOffline = false
    var showNotifs = false
    var showWelcomeTour = false
    var errorMessage: String?
    var historyFilter = "All"

    // Log Catch flow
    var showLogCatch = false
    var lcStep = 1
    var lcSpecies: String?
    var lcWeight: String = ""
    var lcGround: String = ""
    var lcPhoto = false
    var lcDate = Date()

    // Active records / flows
    var activeCatchID: UUID?
    var listPrice: String = ""
    var listingQty: String = ""
    var listingLocation: String = ""
    var listingPickup: String = "Today, after 3:00 PM"
    var listingNotes: String = ""
    var selectedBuyer: Buyer?
    var saleResult: SaleResult?
    var priceSel: String = "Galunggong"
    var marketListings: [OtherListing] = []
    var marketIsSample = true
    var marketSearch = ""
    var myOffers: [Offer] = []
    var payingOfferID: UUID?

    // Advisor
    var advisorSuggestionsUsed: Set<Int> = []

    func resetLogCatch() {
        lcStep = 1
        lcSpecies = nil
        lcWeight = ""
        lcGround = currentUserLandingSite
        lcPhoto = false
        lcDate = Date()
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
        SupabaseClient.shared.signOut()
        phase = .onboarding
        obStep = 0
        tab = .home
        path = NavigationPath()
        currentUserID = nil
        currentUserName = ""
        currentUserRole = "fisher"
        currentBusinessName = ""
        currentUserVerified = false
        marketListings = []
        myOffers = []
    }

    func applyUser(_ user: UserAccount) {
        currentUserID = user.id
        currentUserName = user.fullName
        currentUserMunicipality = user.municipality
        currentUserProvince = user.province
        currentUserLandingSite = user.landingSite
        currentUserFID = user.fisherfolkID
        currentUserMobile = user.mobile
        currentUserRole = user.role
        currentBusinessName = user.businessName
        tab = user.isBuyer ? .market : .home
        listingLocation = "\(currentUserLandingSite)\(currentUserProvince.isEmpty ? "" : ", \(currentUserProvince)")"
    }

    /// "Dalahican Landing Site · Lucena City", built only from what the user entered.
    var currentUserPlace: String {
        let area = currentUserMunicipality.isEmpty
            ? (currentUserProvince.split(separator: ",").first.map(String.init) ?? "")
            : currentUserMunicipality
        return [currentUserLandingSite, area].filter { !$0.isEmpty }.joined(separator: " · ")
    }

    var userInitials: String {
        let parts = currentUserName.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first }
        return letters.isEmpty ? "JD" : String(letters).uppercased()
    }
}
