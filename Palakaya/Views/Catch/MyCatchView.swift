import SwiftUI
import SwiftData

struct MyCatchView: View {
    @Environment(AppState.self) private var appState
    @Query(sort: \CatchRecord.dateLogged, order: .reverse) private var catches: [CatchRecord]

    private var filtered: [CatchRecord] {
        switch appState.historyFilter {
        case "Available": return catches.filter { $0.status == .available }
        case "Sold": return catches.filter { $0.status == .sold }
        default: return catches
        }
    }
    private var monthWeight: Double { catches.reduce(0) { $0 + $1.weight } + 175.6 }

    var body: some View {
        @Bindable var appState = appState
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("My Catch").font(.system(size: 26, weight: .bold)).padding(.top, 16).padding(.bottom, 16)

                HStack(spacing: 8) {
                    StatBox(label: "This Month", value: "\(monthWeight.pkTrimmed) kg")
                    StatBox(label: "Est. Income", value: "₱32,850")
                    StatBox(label: "Trips", value: "14")
                }
                .padding(16)
                .background(Color.pkSurface)
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.pkBorder))
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .padding(.bottom, 16)

                HStack(spacing: 4) {
                    ForEach(["All", "Available", "Sold"], id: \.self) { f in
                        Button {
                            appState.historyFilter = f
                        } label: {
                            Text(f)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(appState.historyFilter == f ? .pkDark : .pkSub)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(appState.historyFilter == f ? Color.white : Color.clear)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
                .padding(4)
                .background(Color.pkSurface2)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.bottom, 16)

                if filtered.isEmpty {
                    EmptyStateView(title: "Your first catch starts here.", cta: "Log My First Catch") {
                        appState.openLogCatch()
                    }
                } else {
                    ForEach(filtered) { c in
                        CatchCardView(record: c) { appState.activeCatchID = c.id; appState.path.append(Route.catchDetails(c.id)) }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 28)
        }
        .background(Color.pkBg)
        .navigationBarHidden(true)
    }
}
