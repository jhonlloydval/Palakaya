import SwiftUI

struct ReportsView: View {
    private let topSpecies: [(String, Double)] = [("Galunggong", 68.4), ("Tulingan", 42.1), ("Tamban", 38.6)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                LabelCaps(text: "September 2026").padding(.bottom, 12)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    reportBox("Total Catch", "184.7 kg")
                    reportBox("Recorded Sales", "₱32,850")
                    reportBox("Avg. Price Alignment", "97%")
                    reportBox("Fishing Trips", "14")
                }
                .padding(.bottom, 16)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Catch Weight Over Time").font(.system(size: 14, weight: .semibold))
                    SparklineChart(data: [22, 30, 18, 35, 28, 40, 32], color: .pkAqua)
                }
                .padding(16)
                .background(Color.pkSurface).overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.pkBorder))
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .padding(.bottom, 16)

                Text("Top Species").font(.system(size: 14, weight: .semibold)).padding(.bottom, 8)
                ForEach(topSpecies, id: \.0) { name, kg in
                    HStack {
                        Text(name).font(.system(size: 14))
                        Spacer()
                        Text("\(String(format: "%.1f", kg)) kg").font(.system(size: 13.5, weight: .semibold))
                    }
                    .padding(.vertical, 8)
                    Divider().overlay(Color.pkBorder)
                }

                HStack(spacing: 12) {
                    GhostButton(title: "Download", systemImage: "arrow.down.circle") {}
                    GhostButton(title: "Share", systemImage: "square.and.arrow.up") {}
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
