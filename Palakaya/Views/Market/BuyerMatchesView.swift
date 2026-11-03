import SwiftUI
import SwiftData

/// Offers from buyers on one of the fisher's listings. Uses real offers from the cloud;
/// without a connection it shows sample buyers so the flow can still be demonstrated.
struct BuyerMatchesView: View {
    var catchID: UUID
    @Environment(AppState.self) private var appState
    @Query private var catches: [CatchRecord]
    @State private var busyOfferID: UUID?
    private var record: CatchRecord? { catches.first { $0.id == catchID } }

    private var realOffers: [Offer] { OfferController.pendingOffers(for: catchID, in: appState.myOffers) }
    private var usingSamples: Bool { !OfferController.isAvailable }

    var body: some View {
        if let c = record {
            let fair = c.fair
            let buyers = usingSamples ? BUYERS : realOffers.map { Buyer(offer: $0, fair: fair) }
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text(buyers.isEmpty ? "No offers yet for your \(c.species)"
                         : "\(buyers.count) \(buyers.count == 1 ? "Buyer" : "Buyers") Interested in your \(c.species)")
                        .font(.system(size: 15, weight: .semibold)).padding(.bottom, 8)
                    if usingSamples {
                        InfoBox(text: "Offline: showing sample buyers. Connect to see real offers.").padding(.bottom, 12)
                    } else if buyers.isEmpty {
                        Text("Buyers will see your listing in their Market. Pull down to check for new offers.")
                            .font(.system(size: 13)).foregroundColor(.pkSub).padding(.bottom, 12)
                    }

                    ForEach(buyers) { b in card(b, catchRecord: c, fair: fair) }
                }
                .padding(.horizontal, 20).padding(.bottom, 28)
            }
            .background(Color.pkBg)
            .navigationTitle("Buyer Matches")
            .navigationBarTitleDisplayMode(.inline)
            .task { await OfferController.refresh(appState: appState) }
            .refreshable { await OfferController.refresh(appState: appState) }
        }
    }

    private func card(_ b: Buyer, catchRecord c: CatchRecord, fair: FairPriceInfo?) -> some View {
        let belowPct = fair.map { Int((1 - Double(b.offer) / Double($0.mid)) * 100) } ?? 0
        let quantity = b.quantity ?? c.weight
        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(b.name).font(.system(size: 14, weight: .semibold))
                        if b.verified {
                            Image(systemName: "checkmark.seal.fill").font(.system(size: 12)).foregroundColor(.pkDark)
                                .accessibilityLabel("Verified buyer")
                        }
                    }
                    Text("\(b.type) · \(b.trans) paid \(b.trans == 1 ? "purchase" : "purchases")")
                        .font(.system(size: 13)).foregroundColor(.pkSub)
                }
                Spacer()
                if b.rating > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "star.fill").font(.system(size: 12)).foregroundColor(.pkWarning)
                        Text(String(format: "%.1f", b.rating)).font(.system(size: 12, weight: .semibold))
                    }
                }
            }
            .padding(.bottom, 8)

            HStack {
                Text("₱\(b.offer)/kg").font(.system(size: 20, weight: .bold)).foregroundColor(.pkDark)
                b.fair ? Badge(tone: .success, text: "Within benchmark") : Badge(tone: .warning, text: "Below Fair Price")
            }
            .padding(.bottom, 8)

            if !b.fair && belowPct > 0 {
                Text("This offer is around \(belowPct)% below the current local benchmark.")
                    .font(.system(size: 12)).foregroundColor(.pkWarning).padding(.bottom, 8)
            }
            if !b.verified && b.offerID != nil {
                Text("This buyer is not verified yet. Agree on pickup in a public place.")
                    .font(.system(size: 12)).foregroundColor(.pkSub).padding(.bottom, 8)
            }
            if !b.message.isEmpty {
                Text("“\(b.message)”").font(.system(size: 13)).italic().foregroundColor(.pkText).padding(.bottom, 8)
            }

            HStack(spacing: 4) {
                Image(systemName: "mappin.circle.fill").font(.system(size: 11)).foregroundColor(.pkSub)
                Text([b.distance.isEmpty ? nil : b.distance,
                      "\(quantity.pkTrimmed) kg · total ₱\(Int(quantity * Double(b.offer)).formatted())"]
                    .compactMap { $0 }.joined(separator: " · "))
                    .font(.system(size: 12.5)).foregroundColor(.pkSub)
            }
            .padding(.bottom, 12)

            HStack(spacing: 12) {
                if let offerID = b.offerID {
                    GhostButton(title: busyOfferID == offerID ? "…" : "Decline") { decline(offerID) }
                } else {
                    GhostButton(title: "Contact") {}
                }
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

    private func decline(_ offerID: UUID) {
        guard let offer = appState.myOffers.first(where: { $0.id == offerID }) else { return }
        busyOfferID = offerID
        Task {
            defer { busyOfferID = nil }
            do { try await OfferController.respond(to: offer, accept: false, appState: appState) }
            catch { appState.errorMessage = error.localizedDescription }
        }
    }
}
