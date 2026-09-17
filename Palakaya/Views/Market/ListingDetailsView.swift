import SwiftUI
import SwiftData

struct ListingDetailsView: View {
    var catchID: UUID
    @Environment(AppState.self) private var appState
    @Query private var catches: [CatchRecord]
    private var record: CatchRecord? { catches.first { $0.id == catchID } }

    var body: some View {
        @Bindable var appState = appState
        if let c = record {
            let fair = c.fair
            let total = Int(c.weight * (c.price ?? 0))
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 18).fill(Color.pkSurface2).frame(height: 144)
                        Image(systemName: "water.waves").font(.system(size: 36)).foregroundColor(.pkAqua)
                    }.padding(.bottom, 16)

                    Text(c.species).font(.system(size: 22, weight: .bold))
                    Text("\(c.weight.pkTrimmed) kg available").font(.system(size: 13)).foregroundColor(.pkSub).padding(.bottom, 12)

                    HStack {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("₱\(Int(c.price ?? 0))").font(.system(size: 24, weight: .bold)).foregroundColor(.pkDark)
                            Text("/kg").font(.system(size: 14)).foregroundColor(.pkSub)
                        }
                        Badge(tone: .success, text: "FAIR PRICE", systemImage: "checkmark")
                    }
                    .padding(.bottom, 16)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Total").font(.system(size: 13)).foregroundColor(.pkSub)
                        Text("₱\(total.formatted())").font(.system(size: 20, weight: .bold))
                        Divider().overlay(Color.pkBorder)
                        HStack(spacing: 4) {
                            Text(appState.currentUserName).font(.system(size: 14, weight: .semibold))
                            Image(systemName: "checkmark.seal.fill").font(.system(size: 12)).foregroundColor(.pkDark)
                        }
                        Text("Verified Fisher · 4.9 ★").font(.system(size: 13)).foregroundColor(.pkSub)
                    }
                    .padding(16)
                    .background(Color.pkSurface).overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.pkBorder))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .padding(.bottom, 16)

                    HStack { Text("Landing Site").foregroundColor(.pkSub); Spacer(); Text(appState.currentUserLandingSite).font(.system(size: 13.5, weight: .semibold)) }
                        .font(.system(size: 13)).padding(.bottom, 6)
                    HStack { Text("Caught").foregroundColor(.pkSub); Spacer(); Text("Today · \(c.timeLabel)").font(.system(size: 13.5, weight: .semibold)) }
                        .font(.system(size: 13)).padding(.bottom, 20)

                    if let fair {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Fair Price Insight").font(.system(size: 13, weight: .semibold)).foregroundColor(.pkDark)
                            Text("Regional range: ₱\(fair.low)–₱\(fair.high)/kg. This listing is within the typical selling range for \(c.species) in your area.")
                                .font(.system(size: 12.5)).foregroundColor(.pkText).lineSpacing(3)
                        }
                        .padding(16)
                        .background(Color.pkSurface2)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .padding(.bottom, 24)
                    }

                    PrimaryButton(title: "\(c.buyersInterested ?? 2) Buyers Interested") {
                        appState.path.append(Route.buyerMatches(c.id))
                    }
                }
                .padding(.horizontal, 20).padding(.bottom, 28)
            }
            .background(Color.pkBg)
            .navigationTitle("Listing")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
