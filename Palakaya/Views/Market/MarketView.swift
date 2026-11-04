import SwiftUI
import SwiftData

struct MarketView: View {
    @Environment(AppState.self) private var appState
    @Query private var allCatches: [CatchRecord]
    private var catches: [CatchRecord] { allCatches.owned(by: appState.currentUserID) }

    private var mine: [CatchRecord] { catches.filter { $0.status == .listed } }
    @State private var sort: MarketSort = .newest

    var body: some View {
        @Bindable var appState = appState
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text(appState.isBuyer ? "Buy Fresh Catch" : "Marketplace")
                    .font(.system(size: 26, weight: .bold)).padding(.top, 16).padding(.bottom, 16)

                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass").foregroundColor(.pkSub)
                    TextField("Search fish, seller or place", text: $appState.marketSearch)
                        .font(.system(size: 16))
                        .autocorrectionDisabled()
                }
                .padding(.horizontal, 14).padding(.vertical, 11)
                .background(Color.pkSurface)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.pkBorder))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.bottom, 12)

                if !appState.isBuyer {
                SectionHeading(title: "Your Listings")
                if mine.isEmpty {
                    EmptyStateView(title: "Nothing for sale yet.", cta: "List a Catch") { appState.goTab(.catchTab) }
                } else {
                    ForEach(mine) { c in
                        MarketCardView(species: c.species, weight: c.weight, price: Int(c.price ?? 0),
                                       mine: true,
                                       buyersInterested: OfferController.pendingOffers(for: c.id, in: appState.myOffers).count,
                                       seller: nil, rating: nil, site: nil, distance: nil, fresh: false) {
                            appState.activeCatchID = c.id
                            appState.path.append(Route.listingDetails(c.id))
                        }
                    }
                }

                }

                HStack(alignment: .center) {
                    SectionHeading(title: appState.marketIsSample ? "Sample Listings"
                                   : (appState.isBuyer ? "Fresh Catch From Fishers" : "From Other Fishers"))
                    Menu {
                        Picker("Sort", selection: $sort) {
                            ForEach(MarketSort.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                        }
                    } label: {
                        Label(sort.rawValue, systemImage: "arrow.up.arrow.down")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.pkDark)
                            .frame(minHeight: 44)
                    }
                    .accessibilityLabel("Sort listings, now \(sort.rawValue)")
                }
                if appState.marketIsSample {
                    InfoBox(text: "These are sample listings. Sign in with cloud sync on to see real catches for sale.")
                        .padding(.bottom, 12)
                } else if others.isEmpty {
                    Text(appState.marketSearch.isEmpty ? "No other catches for sale right now. Pull down to refresh." : "No listings match your search.")
                        .font(.system(size: 13)).foregroundColor(.pkSub).padding(.vertical, 8)
                }
                ForEach(others) { item in
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
        .task { await reload() }
        .refreshable { await reload() }
    }

    private func reload() async {
        await MarketController.refresh(appState: appState)
        await OfferController.refresh(appState: appState)
    }

    private var others: [OtherListing] {
        let q = appState.marketSearch.trimmingCharacters(in: .whitespaces)
        let found = q.isEmpty ? appState.marketListings : appState.marketListings.filter {
            $0.species.localizedCaseInsensitiveContains(q) || $0.seller.localizedCaseInsensitiveContains(q)
                || $0.site.localizedCaseInsensitiveContains(q)
        }
        switch sort {
        case .newest: return found
        case .lowestPrice: return found.sorted { $0.price < $1.price }
        case .fairFirst: return found.filter(\.fair) + found.filter { !$0.fair }
        case .mostKilos: return found.sorted { $0.weight > $1.weight }
        }
    }
}

enum MarketSort: String, CaseIterable {
    case newest = "Newest"
    case lowestPrice = "Lowest price"
    case fairFirst = "Fair price first"
    case mostKilos = "Most kilos"
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
                        Text(buyersInterested == 1 ? "1 offer waiting" : "\(buyersInterested) offers waiting").font(.system(size: 14, weight: .semibold)).foregroundColor(.pkDark)
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "mappin.circle.fill").font(.system(size: 12)).foregroundColor(.pkSub)
                            Text([site, distance].compactMap { $0 }.joined(separator: " · ")).font(.system(size: 12.5)).foregroundColor(.pkSub)
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
