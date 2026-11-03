import SwiftUI

/// Buyer's offers: waiting, accepted (pay now), paid (receipt) and closed.
struct BuyerOffersView: View {
    @Environment(AppState.self) private var appState
    @State private var receipt: Offer?

    private var mine: [Offer] { appState.myOffers.filter(\.iAmBuyer) }
    private var toPay: [Offer] { mine.filter { $0.status == .accepted } }
    private var waiting: [Offer] { mine.filter { $0.status == .pending } }
    private var done: [Offer] { mine.filter { [.paid, .declined, .cancelled].contains($0.status) } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("My Offers").font(.system(size: 26, weight: .bold)).padding(.top, 16).padding(.bottom, 16)

                if !OfferController.isAvailable {
                    InfoBox(text: "Offers need an internet connection. Pull down to try again.")
                } else if mine.isEmpty {
                    EmptyStateView(title: "No offers yet.", cta: "Browse Fresh Catch") { appState.goTab(.market) }
                }

                section("Accepted · Pay Now", toPay)
                section("Waiting for the Fisher", waiting)
                section("History", done)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 28)
        }
        .background(Color.pkBg)
        .navigationBarHidden(true)
        .task { await OfferController.refresh(appState: appState) }
        .refreshable { await OfferController.refresh(appState: appState) }
        .sheet(item: $receipt) { PaymentReceiptView(offer: $0) }
    }

    @ViewBuilder
    private func section(_ title: String, _ offers: [Offer]) -> some View {
        if !offers.isEmpty {
            SectionHeading(title: title)
            ForEach(offers) { offer in card(offer) }
        }
    }

    private func card(_ offer: Offer) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(offer.species) · \(offer.quantityKg.pkTrimmed) kg").font(.system(size: 16, weight: .semibold))
                    Text("from \(offer.fisherFirstName)\(offer.fisherLandingSite.map { " · \($0)" } ?? "")")
                        .font(.system(size: 13)).foregroundColor(.pkSub)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("₱\(offer.total.formatted())").font(.system(size: 17, weight: .bold)).foregroundColor(.pkDark)
                    Text("₱\(offer.pricePerKg.pkTrimmed)/kg").font(.system(size: 12)).foregroundColor(.pkSub)
                }
            }
            statusBadge(offer)

            switch offer.status {
            case .accepted:
                PrimaryButton(title: "Pay ₱\(offer.total.formatted())", systemImage: "creditcard") {
                    appState.payingOfferID = offer.id
                }
            case .pending:
                GhostButton(title: "Cancel Offer") {
                    Task {
                        do { try await OfferController.cancel(offer, appState: appState) }
                        catch { appState.errorMessage = error.localizedDescription }
                    }
                }
            case .paid:
                GhostButton(title: "View Receipt", systemImage: "doc.text") { receipt = offer }
            case .declined, .cancelled:
                EmptyView()
            }
        }
        .padding(16)
        .background(Color.pkSurface)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.pkBorder))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .padding(.bottom, 12)
    }

    private func statusBadge(_ offer: Offer) -> some View {
        switch offer.status {
        case .pending: return Badge(tone: .info, text: "WAITING")
        case .accepted: return Badge(tone: .success, text: "ACCEPTED", systemImage: "checkmark")
        case .paid: return Badge(tone: .success, text: "PAID · \(offer.paymentMethod ?? "")".uppercased(), systemImage: "checkmark")
        case .declined: return Badge(tone: .danger, text: "DECLINED")
        case .cancelled: return Badge(tone: .warning, text: "CANCELLED")
        }
    }
}
