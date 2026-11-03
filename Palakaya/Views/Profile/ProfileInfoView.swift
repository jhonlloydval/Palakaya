import SwiftUI

enum ProfileSection: String, Hashable {
    case personal = "Personal Information"
    case fisherfolk = "Fisherfolk Details"
    case landing = "Landing Site"
    case verification = "Buyer Verification"
    case connectivity = "Connectivity & Offline Data"
    case privacy = "Privacy"
    case help = "Help Center"
    case about = "About Palakaya"
}

/// One simple read-only page for each Profile menu row.
struct ProfileInfoView: View {
    var section: ProfileSection
    @Environment(AppState.self) private var appState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                switch section {
                case .personal:
                    row("Full name", appState.currentUserName)
                    row("Mobile number", appState.currentUserMobile)
                    row("Municipality", appState.currentUserMunicipality)
                    row("Province / Region", appState.currentUserProvince)
                case .fisherfolk:
                    row("Fisherfolk ID", appState.currentUserFID.isEmpty ? "Not added yet" : appState.currentUserFID)
                    InfoBox(text: "Registering with your Municipal Agriculture or Fisheries Office (FishR) helps you qualify for government programs.")
                case .landing:
                    row("Home port / landing site", appState.currentUserLandingSite)
                    row("Province / Region", appState.currentUserProvince)
                case .verification:
                    row("Business", appState.currentBusinessName)
                    row("Status", appState.currentUserVerified ? "Verified ✓" : "Pending review")
                    InfoBox(text: "To get the Verified badge, send a photo of your business permit, cooperative registration or government ID to your Municipal Agriculture Office or the Palakaya team. Fishers see the badge on your offers.")
                case .connectivity:
                    InfoBox(text: "Your catches are saved on this phone, so you can log them even without a signal.")
                    InfoBox(text: "When you have signal, new catches, listings and sales upload to your Palakaya cloud account automatically. Tap the Wi-Fi button on Home to sync now.")
                case .privacy:
                    InfoBox(text: "Your personal catch records stay private. Only anonymized, grouped regional data is shared with BFAR and local government fisheries offices.")
                    InfoBox(text: "We collect only what the app needs: your name, mobile number, location and catch records.")
                case .help:
                    InfoBox(text: "1. Tap Log Catch and pick the fish.\n2. Enter the weight in kilos.\n3. Check the estimated fair price.\n4. List it for sale and compare buyer offers.")
                    InfoBox(text: "Palakaya does not handle payments. Agree on payment and pickup directly with the buyer.")
                case .about:
                    InfoBox(text: "Palakaya helps small-scale Filipino fishers log catches, check estimated fair prices and find buyers. Prices shown are estimates from regional averages, not guaranteed prices.")
                    row("Version", "1.0 (midterm prototype)")
                }
            }
            .padding(.horizontal, 20).padding(.vertical, 16)
        }
        .background(Color.pkBg)
        .navigationTitle(section.rawValue)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func row(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.system(size: 13)).foregroundColor(.pkSub)
            Text(value.isEmpty ? "—" : value).font(.system(size: 16, weight: .semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.pkSurface)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.pkBorder))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
