import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var appState = appState
        NavigationStack(path: $appState.path) {
            tabRoot
                .navigationDestination(for: Route.self) { route in
                    destination(for: route)
                }
        }
        .safeAreaInset(edge: .bottom) {
            if appState.path.isEmpty {
                CustomTabBar()
            }
        }
        .sheet(isPresented: $appState.showLogCatch) {
            LogCatchFlowView()
        }
        .sheet(isPresented: $appState.showNotifs) {
            NotificationsSheetView()
                .presentationDetents([.fraction(0.7)])
                .presentationDragIndicator(.visible)
        }
        .tint(.pkDark)
    }

    @ViewBuilder
    private var tabRoot: some View {
        switch appState.tab {
        case .home: HomeView()
        case .catchTab: MyCatchView()
        case .market: MarketView()
        case .advisor: AdvisorView()
        case .profile: ProfileView()
        }
    }

    @ViewBuilder
    private func destination(for route: Route) -> some View {
        switch route {
        case .catchDetails(let id): CatchDetailsView(catchID: id)
        case .createListing(let id): CreateListingView(catchID: id)
        case .listingDetails(let id): ListingDetailsView(catchID: id)
        case .otherListingDetails(let itemID): OtherListingDetailsView(itemID: itemID)
        case .buyerMatches(let id): BuyerMatchesView(catchID: id)
        case .recordSale(let id): RecordSaleView(catchID: id)
        case .saleRecorded: SaleRecordedView()
        case .priceExplorer: PriceExplorerView()
        case .reports: ReportsView()
        }
    }
}

struct CustomTabBar: View {
    @Environment(AppState.self) private var appState

    private let tabs: [(AppTab, String, String)] = [
        (.home, "Home", "house.fill"),
        (.catchTab, "Catch", "water.waves"),
        (.market, "Market", "storefront.fill"),
        (.advisor, "Advisor", "sparkles"),
        (.profile, "Profile", "person.fill"),
    ]

    var body: some View {
        HStack {
            ForEach(tabs, id: \.0) { tab, label, icon in
                let isActive = appState.tab == tab
                let isCatch = tab == .catchTab
                Button {
                    appState.goTab(tab)
                } label: {
                    VStack(spacing: 4) {
                        ZStack {
                            Circle()
                                .fill(isCatch ? AnyShapeStyle(LinearGradient.pkBrand) : AnyShapeStyle(Color.clear))
                                .frame(width: 36, height: 36)
                            Image(systemName: icon)
                                .font(.system(size: 17))
                                .foregroundColor(isCatch ? .white : (isActive ? .pkDark : .pkSub))
                        }
                        Text(label)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(isActive ? .pkDark : .pkSub)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background(.ultraThinMaterial)
        .overlay(Rectangle().fill(Color.pkBorder).frame(height: 1), alignment: .top)
    }
}
