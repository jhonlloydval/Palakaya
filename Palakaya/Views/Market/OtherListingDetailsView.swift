import SwiftUI

struct OtherListingDetailsView: View {
    var itemID: String
    @Environment(AppState.self) private var appState
    private var item: OtherListing? { appState.marketListings.first { $0.id == itemID } }
    @State private var showOffer = false

    /// The buyer's latest offer on this listing, if any.
    private var myOffer: Offer? {
        appState.myOffers.first { $0.iAmBuyer && $0.catchID.uuidString == itemID && $0.status != .cancelled }
    }

    var body: some View {
        if let item {
            let fair = FAIR_DB[item.species]
            let total = Int(item.weight * Double(item.price))
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 18).fill(Color.pkSurface2).frame(height: 144)
                        Image(systemName: "water.waves").font(.system(size: 40)).foregroundColor(.pkAqua)
                    }.padding(.bottom, 16)

                    Text(item.species).font(.system(size: 22, weight: .bold))
                    Text("\(item.weight.pkTrimmed) kg available").font(.system(size: 13)).foregroundColor(.pkSub).padding(.bottom, 12)

                    HStack {
                        Text("₱\(item.price)/kg").font(.system(size: 24, weight: .bold)).foregroundColor(.pkDark)
                        item.fair ? Badge(tone: .success, text: "FAIR PRICE", systemImage: "checkmark") : Badge(tone: .warning, text: "BELOW FAIR")
                    }
                    .padding(.bottom, 16)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Total estimated price").font(.system(size: 13)).foregroundColor(.pkSub)
                        Text("₱\(total.formatted())").font(.system(size: 20, weight: .bold))
                        Divider().overlay(Color.pkBorder)
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.seller).font(.system(size: 14, weight: .semibold))
                                HStack(spacing: 4) {
                                    Image(systemName: "mappin.circle.fill").font(.system(size: 11)).foregroundColor(.pkSub)
                                    Text([item.site, item.distance].compactMap { $0 }.joined(separator: " · "))
                                        .font(.system(size: 12)).foregroundColor(.pkSub)
                                }
                            }
                            Spacer()
                            if let rating = item.rating {
                                HStack(spacing: 3) {
                                    Image(systemName: "star.fill").font(.system(size: 13)).foregroundColor(.pkWarning)
                                    Text(String(format: "%.1f", rating)).font(.system(size: 13, weight: .semibold))
                                }
                            }
                        }
                    }
                    .padding(16)
                    .background(Color.pkSurface).overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.pkBorder))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .padding(.bottom, 16)

                    if let fair {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Fair Price Insight").font(.system(size: 13, weight: .semibold)).foregroundColor(.pkDark)
                            Text("Regional range for \(item.species) today is ₱\(fair.low)–₱\(fair.high)/kg. This listing is \(item.fair ? "within" : "below") the typical selling range.")
                                .font(.system(size: 12.5)).foregroundColor(.pkText).lineSpacing(3)
                        }
                        .padding(16)
                        .background(Color.pkSurface2)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .padding(.bottom, 24)
                    }

                    if appState.isBuyer && item.contactMobile != nil {
                        if let offer = myOffer {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Your offer: ₱\(offer.pricePerKg.pkTrimmed)/kg · \(offer.quantityKg.pkTrimmed) kg")
                                    .font(.system(size: 14, weight: .semibold))
                                Text(offer.status.label).font(.system(size: 13)).foregroundColor(.pkSub)
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.pkSurface2)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .padding(.bottom, 12)
                            if offer.status == .declined {
                                PrimaryButton(title: "Make a New Offer") { showOffer = true }.padding(.bottom, 12)
                            } else {
                                GhostButton(title: "See My Offers", systemImage: "tag") { appState.goTab(.offers) }
                                    .padding(.bottom, 12)
                            }
                        } else {
                            PrimaryButton(title: "Make an Offer", systemImage: "tag") { showOffer = true }
                                .padding(.bottom, 12)
                        }
                    }

                    if let mobile = item.contactMobile, let call = URL(string: "tel:\(mobile)"),
                       let text = URL(string: "sms:\(mobile)") {
                        HStack(spacing: 12) {
                            contactLink("Call", "phone.fill", call)
                            contactLink("Text", "message.fill", text)
                        }
                        InfoBox(text: appState.isBuyer
                                ? "After the fisher accepts, pay in the app with GCash, Maya or LandBank (demo payment), then agree on pickup."
                                : "Agree on price and pickup directly with the fisher.")
                            .padding(.top, 12)
                    } else {
                        InfoBox(text: "Sample listing: contact details appear on real listings from other fishers.")
                    }
                }
                .padding(.horizontal, 20).padding(.bottom, 28)
            }
            .background(Color.pkBg)
            .sheet(isPresented: $showOffer) { MakeOfferView(listing: item) }
            .navigationTitle(item.species)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func contactLink(_ title: String, _ icon: String, _ url: URL) -> some View {
        Link(destination: url) {
            Label(title, systemImage: icon)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 52)
                .background(Color.pkDark)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
}
