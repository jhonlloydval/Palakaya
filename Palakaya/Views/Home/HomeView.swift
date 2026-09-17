import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(AppState.self) private var appState
    @Query(sort: \CatchRecord.dateLogged, order: .reverse) private var catches: [CatchRecord]

    private var todayWeight: Double { catches.reduce(0) { $0 + $1.weight } }
    private var todayValue: Double { catches.reduce(0) { $0 + $1.weight * Double(FAIR_DB[$1.species]?.mid ?? 0) } }

    var body: some View {
        @Bindable var appState = appState
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Magandang umaga, \(appState.currentUserName.split(separator: " ").first.map(String.init) ?? "Mang Jose") 👋")
                            .font(.system(size: 19, weight: .bold))
                        HStack(spacing: 4) {
                            Image(systemName: "mappin.circle.fill").font(.system(size: 12)).foregroundColor(.pkSub)
                            Text("\(appState.currentUserLandingSite) · \(appState.currentUserProvince.split(separator: ",").first.map(String.init) ?? "Batangas")")
                                .font(.system(size: 13)).foregroundColor(.pkSub)
                        }
                    }
                    Spacer()
                    HStack(spacing: 8) {
                        Button { appState.isOffline.toggle() } label: {
                            ZStack {
                                Circle().fill(Color.pkSurface2).frame(width: 36, height: 36)
                                Image(systemName: appState.isOffline ? "wifi.slash" : "wifi")
                                    .foregroundColor(appState.isOffline ? .pkWarning : .pkSuccess)
                                    .font(.system(size: 15))
                            }
                        }
                        Button { appState.showNotifs = true } label: {
                            ZStack(alignment: .topTrailing) {
                                Circle().fill(Color.pkSurface2).frame(width: 36, height: 36)
                                Image(systemName: "bell.fill").foregroundColor(.pkDark).font(.system(size: 15))
                                Circle().fill(Color.pkDanger).frame(width: 7, height: 7).offset(x: 2, y: -1)
                            }
                        }
                        ZStack {
                            Circle().fill(Color.pkDark).frame(width: 36, height: 36)
                            Text(appState.userInitials).font(.system(size: 12, weight: .bold)).foregroundColor(.white)
                        }
                    }
                }
                .padding(.top, 12)
                .padding(.bottom, 20)

                // Hero card
                VStack(alignment: .leading, spacing: 0) {
                    Text("TODAY'S CATCH").font(.system(size: 12.5, weight: .semibold)).foregroundColor(.white.opacity(0.8)).tracking(0.3)
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text(String(format: "%.1f", todayWeight)).font(.system(size: 34, weight: .bold))
                        Text("kg").font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.bottom, 14)

                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Estimated value").font(.system(size: 12)).foregroundColor(.white.opacity(0.7))
                            Text("₱\(Int(todayValue).formatted())").font(.system(size: 20, weight: .bold)).foregroundColor(.white)
                        }
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.right").font(.system(size: 11, weight: .bold))
                            Text("+12% vs. average").font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 11).padding(.vertical, 6)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Capsule())
                    }
                    .padding(.bottom, 16)

                    Button { appState.openLogCatch() } label: {
                        HStack { Image(systemName: "plus.circle.fill"); Text("Log Catch").fontWeight(.semibold) }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(Color.white)
                            .foregroundColor(.pkDark)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
                .padding(20)
                .background(LinearGradient.pkBrand)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .padding(.bottom, 16)

                // Fair price card
                if let fair = FAIR_DB["Galunggong"] {
                    CardContainer {
                        HStack {
                            Text("Fair Price Today").font(.system(size: 14, weight: .semibold))
                            Spacer()
                            Badge(tone: .success, text: "↑ \(String(format: "%.0f", fair.week))% this week", systemImage: "arrow.up.right")
                        }
                        Text("Galunggong").font(.system(size: 13)).foregroundColor(.pkSub).padding(.top, 2)
                        Text("₱\(fair.low) – ₱\(fair.high) / kg").font(.system(size: 22, weight: .bold)).foregroundColor(.pkDark).padding(.vertical, 4)
                        GhostButton(title: "View Prices") { appState.path.append(Route.priceExplorer) }
                            .padding(.top, 10)
                    }
                    .padding(.bottom, 20)
                }

                // Quick actions
                HStack(spacing: 8) {
                    quickAction("Log Catch", "plus.circle") { appState.openLogCatch() }
                    quickAction("Sell Catch", "storefront") { appState.goTab(.market) }
                    quickAction("Check Price", "chart.line.uptrend.xyaxis") { appState.path.append(Route.priceExplorer) }
                    quickAction("Ask Advisor", "sparkles") { appState.goTab(.advisor) }
                }
                .padding(.bottom, 12)

                SectionHeading(title: "Recent Activity", actionText: "See all") { appState.goTab(.catchTab) }
                ForEach(catches.prefix(2)) { c in
                    CatchCardView(record: c) { appState.activeCatchID = c.id; appState.path.append(Route.catchDetails(c.id)) }
                }

                SectionHeading(title: "Price Watch")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        priceWatch("Galunggong", 192, 4.2, true)
                        priceWatch("Bangus", 178, 1.3, false)
                        priceWatch("Tulingan", 210, 2.8, true)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 28)
        }
        .background(Color.pkBg)
        .navigationBarHidden(true)
        .overlay(alignment: .top) {
            if appState.isOffline { OfflineBanner() }
        }
    }

    private func quickAction(_ label: String, _ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 18)).foregroundColor(.pkDark)
                Text(label).font(.system(size: 10.5, weight: .medium)).foregroundColor(.pkText).multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(Color.pkSurface)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.pkBorder))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    private func priceWatch(_ species: String, _ price: Int, _ trend: Double, _ up: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(species).font(.system(size: 13)).foregroundColor(.pkSub)
            Text("₱\(price)/kg").font(.system(size: 16, weight: .bold))
            HStack(spacing: 2) {
                Image(systemName: up ? "arrow.up.right" : "arrow.down.right").font(.system(size: 9, weight: .bold))
                Text("\(String(format: "%.1f", trend))%").font(.system(size: 11, weight: .semibold))
            }
            .foregroundColor(up ? .pkSuccess : .pkDanger)
        }
        .padding(14)
        .frame(width: 120, alignment: .leading)
        .background(Color.pkSurface)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.pkBorder))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct OfflineBanner: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.slash").font(.system(size: 13)).foregroundColor(.pkWarning)
            Text("Low signal — your catch will sync when connection returns.")
                .font(.system(size: 11.5, weight: .medium)).foregroundColor(.pkWarning)
        }
        .padding(.horizontal, 16).padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(Color.pkWarningBg)
    }
}

struct CatchCardView: View {
    var record: CatchRecord
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(record.species).font(.system(size: 16, weight: .semibold)).foregroundColor(.pkText)
                        Text("\(record.weight.pkTrimmed) kg · \(record.ground)").font(.system(size: 13)).foregroundColor(.pkSub)
                        HStack(spacing: 4) {
                            Image(systemName: "clock").font(.system(size: 11)).foregroundColor(.pkSub)
                            Text("Today · \(record.timeLabel)").font(.system(size: 12)).foregroundColor(.pkSub)
                        }
                    }
                    Spacer()
                    statusBadge
                }
                Divider().overlay(Color.pkBorder).padding(.vertical, 12)
                HStack {
                    Text("Fair Price").font(.system(size: 13)).foregroundColor(.pkSub)
                    Spacer()
                    if let fair = record.fair {
                        Text("₱\(fair.low)–₱\(fair.high)/kg").font(.system(size: 14, weight: .semibold)).foregroundColor(.pkDark)
                    } else {
                        Text("—").foregroundColor(.pkSub)
                    }
                }
                if record.status == .sold, let amount = record.saleAmount {
                    Text("Sold for ₱\(Int(amount).formatted())")
                        .font(.system(size: 13, weight: .medium)).foregroundColor(.pkSuccess)
                        .padding(.top, 8)
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

    @ViewBuilder private var statusBadge: some View {
        switch record.status {
        case .sold: Badge(tone: .info, text: "SOLD")
        case .listed: Badge(tone: .success, text: "LISTED")
        case .available: Badge(tone: .warning, text: "AVAILABLE")
        }
    }
}

extension Double {
    var pkTrimmed: String {
        self.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", self) : String(format: "%.1f", self)
    }
}
