import SwiftUI
import SwiftData

struct NotificationsSheetView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \CatchRecord.dateLogged, order: .reverse) private var allCatches: [CatchRecord]

    private var items: [NotificationItem] {
        NotificationsController.items(catches: allCatches.owned(by: appState.currentUserID),
                                      market: appState.marketListings, marketIsSample: appState.marketIsSample,
                                      offers: appState.myOffers)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Notifications").font(.system(size: 17, weight: .bold))
                Spacer()
                Button { dismiss() } label: { Image(systemName: "xmark").foregroundColor(.pkSub) }
            }
            .padding(.bottom, 16)

            if items.isEmpty {
                Text("No notifications yet. Sales, listings and price updates will show up here.")
                    .font(.system(size: 13.5)).foregroundColor(.pkSub)
                Spacer()
            }
            ScrollView {
                ForEach(items) { n in
                    Button { open(n) } label: {
                    HStack(alignment: .top, spacing: 12) {
                        ZStack {
                            Circle().fill(Color.pkSurface2).frame(width: 36, height: 36)
                            Image(systemName: "bell.fill").font(.system(size: 14)).foregroundColor(.pkDark)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(n.kind).font(.system(size: 11, weight: .bold)).foregroundColor(.pkDark).tracking(0.3)
                            Text(n.text).font(.system(size: 13.5)).foregroundColor(.pkText).lineSpacing(2)
                            Text(n.time).font(.system(size: 11)).foregroundColor(.pkSub)
                        }
                        Spacer(minLength: 0)
                        if n.tab != nil {
                            Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold)).foregroundColor(.pkSub)
                                .padding(.top, 10)
                        }
                    }
                    .padding(.vertical, 12)
                    .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(n.tab == nil)
                    Divider().overlay(Color.pkBorder)
                }
            }
        }
        .padding(20)
        .task { await OfferController.refresh(appState: appState) }
    }

    private func open(_ n: NotificationItem) {
        guard let tab = n.tab else { return }
        dismiss()
        appState.goTab(tab)
        if let route = n.route { appState.path.append(route) }
    }
}
