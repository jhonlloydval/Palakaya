import SwiftUI
import SwiftData

struct BuyerMatchesView: View {
    var catchID: UUID
    @Environment(AppState.self) private var appState
    @Query private var catches: [CatchRecord]
    private var record: CatchRecord? { catches.first { $0.id == catchID } }

    var body: some View {
        @Bindable var appState = appState
        if let c = record, let fair = c.fair {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text("\(BUYERS.count) Buyers Interested in your \(c.species)")
                        .font(.system(size: 15, weight: .semibold)).padding(.bottom, 16)

                    ForEach(BUYERS) { b in
                        let belowPct = Int((1 - Double(b.offer) / Double(fair.mid)) * 100)
                        VStack(alignment: .leading, spacing: 0) {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 4) {
                                        Text(b.name).font(.system(size: 14, weight: .semibold))
                                        if b.verified { Image(systemName: "checkmark.seal.fill").font(.system(size: 12)).foregroundColor(.pkDark) }
                                    }
                                    Text("\(b.type) · \(b.trans) transactions").font(.system(size: 13)).foregroundColor(.pkSub)
                                }
                                Spacer()
                                HStack(spacing: 3) {
                                    Image(systemName: "star.fill").font(.system(size: 12)).foregroundColor(.pkWarning)
                                    Text(String(format: "%.1f", b.rating)).font(.system(size: 12, weight: .semibold))
                                }
                            }
                            .padding(.bottom, 8)

                            HStack {
                                Text("₱\(b.offer)/kg").font(.system(size: 20, weight: .bold)).foregroundColor(.pkDark)
                                b.fair ? Badge(tone: .success, text: "Within benchmark") : Badge(tone: .warning, text: "Below Fair Price")
                            }
                            .padding(.bottom, 8)

                            if !b.fair {
                                Text("This offer is around \(belowPct)% below the current local benchmark.")
                                    .font(.system(size: 12)).foregroundColor(.pkWarning).padding(.bottom, 8)
                            }

                            HStack(spacing: 4) {
                                Image(systemName: "mappin.circle.fill").font(.system(size: 11)).foregroundColor(.pkSub)
                                Text("\(b.distance) away · Est. total ₱\(Int(c.weight * Double(b.offer)).formatted())")
                                    .font(.system(size: 12.5)).foregroundColor(.pkSub)
                            }
                            .padding(.bottom, 12)

                            HStack(spacing: 12) {
                                GhostButton(title: "Contact") {}
                                PrimaryButton(title: "Accept") {
                                    appState.selectedBuyer = b
                                    appState.activeCatchID = c.id
                                    appState.path.append(Route.recordSale(c.id))
                                }
                            }
                        }
                        .padding(16)
                        .background(Color.pkSurface).overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.pkBorder))
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .padding(.bottom, 12)
                    }
                }
                .padding(.horizontal, 20).padding(.bottom, 28)
            }
            .background(Color.pkBg)
            .navigationTitle("Buyer Matches")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
