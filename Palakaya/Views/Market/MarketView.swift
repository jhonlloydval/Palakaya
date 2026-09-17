import SwiftUI
import SwiftData

struct MarketView: View {
    @Environment(AppState.self) private var appState
    @Query private var catches: [CatchRecord]

    private var mine: [CatchRecord] { catches.filter { $0.status == .listed } }

    var body: some View {
        @Bindable var appState = appState
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Marketplace").font(.system(size: 26, weight: .bold)).padding(.top, 16).padding(.bottom, 16)

                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass").foregroundColor(.pkSub)
                    Text("Search catch or buyer").foregroundColor(.pkSub).font(.system(size: 14))
                    Spacer()
                }
                .padding(.horizontal, 14).padding(.vertical, 11)
                .background(Color.pkSurface)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.pkBorder))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.bottom, 12)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        chip("Nearby", "slider.horizontal.3")
                        chip("Species")
                        chip("Price")
                        chip("Newest")
                    }
                }
                .padding(.bottom, 8)

                SectionHeading(title: "Your Listings")
                if mine.isEmpty {
                    EmptyStateView(title: "Nothing for sale yet.", cta: "List a Catch") { appState.goTab(.catchTab) }
                } else {
                    ForEach(mine) { c in
                        MarketCardView(species: c.species, weight: c.weight, price: Int(c.price ?? 0),
                                       mine: true, buyersInterested: c.buyersInterested ?? 0,
                                       seller: nil, rating: nil, site: nil, distance: nil, fresh: false) {
                            appState.activeCatchID = c.id
                            appState.path.append(Route.listingDetails(c.id))
                        }
                    }
                }

                SectionHeading(title: "Available Near You")
                ForEach(OTHER_LISTINGS) { item in
                    MarketCardView(species: item.species, weight: item.weight, price: item.price,
                                   mine: false, buyersInterested: 0,
                                   seller: item.seller, rating: item.rating, site: item.site, distance: item.distance, fresh: item.fresh) {
                        appState.path.append(Route.otherListingDetails(item.id))
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 28)
        }
        .background(Color.pkBg)
        .navigationBarHidden(true)
    }

    private func chip(_ text: String, _ icon: String? = nil) -> some View {
        HStack(spacing: 4) {
            if let icon { Image(systemName: icon).font(.system(size: 10)) }
            Text(text).font(.system(size: 12.5, weight: .medium))
        }
        .foregroundColor(.pkText)
        .padding(.horizontal, 14).padding(.vertical, 7)
        .overlay(Capsule().stroke(Color.pkBorder))
    }
}

struct MarketCardView: View {
    var species: String
    var weight: Double
    var price: Int
    var mine: Bool
    var buyersInterested: Int
    var seller: String?
    var rating: Double?
    var site: String?
    var distance: String?
    var fresh: Bool
    var action: () -> Void

    private var fair: FairPriceInfo? { FAIR_DB[species] }
    private var total: Int { Int(weight * Double(price)) }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(species).font(.system(size: 16, weight: .semibold)).foregroundColor(.pkText)
                        Text("\(weight.pkTrimmed) kg available").font(.system(size: 13)).foregroundColor(.pkSub)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text("₱\(price)").font(.system(size: 17, weight: .bold)).foregroundColor(.pkDark)
                            Text("/kg").font(.system(size: 12)).foregroundColor(.pkSub)
                        }
                        Text("≈ ₱\(total.formatted()) total").font(.system(size: 12)).foregroundColor(.pkSub)
                    }
                }
                HStack(spacing: 6) {
                    if let fair {
                        if price >= fair.low { Badge(tone: .success, text: "FAIR PRICE", systemImage: "checkmark") }
                        else { Badge(tone: .warning, text: "BELOW FAIR") }
                    }
                    if fresh { Badge(tone: .info, text: "FRESH TODAY") }
                }
                .padding(.top, 9)

                Divider().overlay(Color.pkBorder).padding(.vertical, 12)
                HStack {
                    if mine {
                        Text("\(buyersInterested) buyers interested").font(.system(size: 14, weight: .semibold)).foregroundColor(.pkDark)
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "mappin.circle.fill").font(.system(size: 12)).foregroundColor(.pkSub)
                            Text("\(site ?? "") · \(distance ?? "")").font(.system(size: 12.5)).foregroundColor(.pkSub)
                        }
                    }
                    Spacer()
                    if let rating {
                        HStack(spacing: 3) {
                            Image(systemName: "star.fill").font(.system(size: 11)).foregroundColor(.pkWarning)
                            Text(String(format: "%.1f", rating)).font(.system(size: 12, weight: .medium)).foregroundColor(.pkText)
                        }
                    }
                }
            }
            .padding(16)
            .background(Color.pkSurface)
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.pkBorder))
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
        .padding(.bottom, 12)
    }
}
