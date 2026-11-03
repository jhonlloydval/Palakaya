import SwiftUI
import SwiftData

struct ReportsView: View {
    @Environment(AppState.self) private var appState
    @Query private var allCatches: [CatchRecord]
    private var catches: [CatchRecord] { allCatches.owned(by: appState.currentUserID) }

    private var summary: ReportSummary { ReportsController.summary(for: catches) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                LabelCaps(text: summary.monthLabel).padding(.bottom, 12)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    reportBox("Total Catch", "\(summary.totalKg.pkTrimmed) kg")
                    reportBox("Recorded Sales", "₱\(summary.salesTotal.formatted())")
                    reportBox("Avg. Price Alignment", summary.averageAlignment.map { "\($0)%" } ?? "—")
                    reportBox("Fishing Days", "\(summary.fishingDays)")
                }
                .padding(.bottom, 16)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Catch Weight, Last 7 Days").font(.system(size: 14, weight: .semibold))
                    SparklineChart(data: summary.dailyKg.map { Int($0.rounded()) }, color: .pkAqua)
                }
                .padding(16)
                .background(Color.pkSurface).overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.pkBorder))
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .padding(.bottom, 16)

                Text("Top Species").font(.system(size: 14, weight: .semibold)).padding(.bottom, 8)
                if summary.topSpecies.isEmpty {
                    Text("Log a catch this month to see your top species.")
                        .font(.system(size: 13)).foregroundColor(.pkSub).padding(.vertical, 8)
                }
                ForEach(summary.topSpecies, id: \.name) { item in
                    HStack {
                        Text(item.name).font(.system(size: 14))
                        Spacer()
                        Text("\(item.kg.pkTrimmed) kg").font(.system(size: 13.5, weight: .semibold))
                    }
                    .padding(.vertical, 8)
                    Divider().overlay(Color.pkBorder)
                }

                ShareLink(item: summary.shareText) {
                    Label("Share Report", systemImage: "square.and.arrow.up")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 52)
                        .background(Color.pkSurface)
                        .foregroundColor(.pkDark)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.pkBorder))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .padding(.top, 20)
            }
            .padding(.horizontal, 20).padding(.bottom, 28)
        }
        .background(Color.pkBg)
        .navigationTitle("My Reports")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func reportBox(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.system(size: 13)).foregroundColor(.pkSub)
            Text(value).font(.system(size: 20, weight: .bold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.pkSurface).overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.pkBorder))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}
