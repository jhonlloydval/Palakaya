import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(AppState.self) private var appState
    @Query private var catches: [CatchRecord]

    private var totalKg: Double { catches.reduce(0) { $0 + $1.weight } }
    private var sales: Int { catches.filter { $0.status == .sold }.count }

    private let rows: [(String, String, Route?)] = [
        ("person.fill", "Personal Information", nil),
        ("water.waves", "Fisherfolk Details", nil),
        ("mappin.circle.fill", "Landing Site", nil),
        ("star.fill", "Saved Buyers", nil),
        ("doc.text.fill", "Reports", .reports),
        ("wifi", "Connectivity & Offline Data", nil),
        ("lock.fill", "Privacy", nil),
        ("questionmark.circle.fill", "Help Center", nil),
        ("info.circle.fill", "About Palakaya", nil),
    ]

    var body: some View {
        @Bindable var appState = appState
        ScrollView {
            VStack(spacing: 0) {
                VStack(spacing: 8) {
                    ZStack {
                        Circle().fill(LinearGradient.pkBrand).frame(width: 80, height: 80)
                        Text(appState.userInitials).font(.system(size: 24, weight: .bold)).foregroundColor(.white)
                    }
                    HStack(spacing: 4) {
                        Text(appState.currentUserName.isEmpty ? "Mang Jose Dela Cruz" : appState.currentUserName)
                            .font(.system(size: 18, weight: .bold))
                        Image(systemName: "checkmark.seal.fill").font(.system(size: 14)).foregroundColor(.pkDark)
                    }
                    Text("Verified Municipal Fisher").font(.system(size: 13)).foregroundColor(.pkSub)
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.circle.fill").font(.system(size: 11)).foregroundColor(.pkSub)
                        Text(appState.currentUserLandingSite.isEmpty ? "Sabang Landing Site, Batangas" : "\(appState.currentUserLandingSite), \(appState.currentUserProvince)")
                            .font(.system(size: 12.5)).foregroundColor(.pkSub)
                    }
                }
                .padding(.top, 22)
                .padding(.bottom, 20)

                HStack(spacing: 0) {
                    StatBox(label: "Caught", value: "\(Int(totalKg))kg")
                    Divider().overlay(Color.pkBorder)
                    StatBox(label: "Sales", value: "\(sales)")
                    Divider().overlay(Color.pkBorder)
                    StatBox(label: "Rating", value: "4.9★")
                }
                .padding(16)
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.pkBorder))
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .padding(.bottom, 20)

                VStack(spacing: 0) {
                    ForEach(Array(rows.enumerated()), id: \.offset) { i, row in
                        Button {
                            if let route = row.2 { appState.path.append(route) }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: row.0).font(.system(size: 16)).foregroundColor(.pkDark).frame(width: 20)
                                Text(row.1).font(.system(size: 14, weight: .medium)).foregroundColor(.pkText)
                                Spacer()
                                Image(systemName: "chevron.right").font(.system(size: 13)).foregroundColor(.pkSub)
                            }
                            .padding(.horizontal, 16).padding(.vertical, 14)
                        }
                        .buttonStyle(.plain)
                        if i < rows.count - 1 { Divider().overlay(Color.pkBorder).padding(.leading, 48) }
                    }
                }
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.pkBorder))
                .clipShape(RoundedRectangle(cornerRadius: 18))

                Button {
                    appState.logout()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("Log Out")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.pkDanger)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
                .padding(.top, 16)
            }
            .padding(.horizontal, 20).padding(.bottom, 28)
        }
        .background(Color.pkBg)
        .navigationBarHidden(true)
    }
}
