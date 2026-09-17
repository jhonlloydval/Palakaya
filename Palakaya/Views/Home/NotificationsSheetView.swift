import SwiftUI

struct NotificationsSheetView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Notifications").font(.system(size: 17, weight: .bold))
                Spacer()
                Button { dismiss() } label: { Image(systemName: "xmark").foregroundColor(.pkSub) }
            }
            .padding(.bottom, 16)

            ScrollView {
                ForEach(NOTIFS) { n in
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
                    }
                    .padding(.vertical, 12)
                    Divider().overlay(Color.pkBorder)
                }
            }
        }
        .padding(20)
    }
}
