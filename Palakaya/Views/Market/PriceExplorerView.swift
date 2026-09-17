import SwiftUI

struct PriceExplorerView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var appState = appState
        let f = FAIR_DB[appState.priceSel]!

        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass").foregroundColor(.pkSub)
                    Text("Search species").foregroundColor(.pkSub).font(.system(size: 14))
                }
                .padding(.horizontal, 14).padding(.vertical, 11)
                .background(Color.pkSurface).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.pkBorder))
                .clipShape(RoundedRectangle(cornerRadius: 12)).padding(.bottom, 12)

                HStack(spacing: 6) {
                    Image(systemName: "mappin.circle.fill").font(.system(size: 13)).foregroundColor(.pkDark)
                    Text("Batangas").font(.system(size: 13, weight: .medium)).foregroundColor(.pkDark)
                    Image(systemName: "chevron.down").font(.system(size: 11)).foregroundColor(.pkDark)
                }
                .padding(.bottom, 16)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(ALL_SPECIES, id: \.self) { sp in
                            Button { appState.priceSel = sp } label: {
                                Text(sp)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(appState.priceSel == sp ? .white : .pkText)
                                    .padding(.horizontal, 14).padding(.vertical, 7)
                                    .background(appState.priceSel == sp ? Color.pkDark : Color.clear)
                                    .overlay(Capsule().stroke(appState.priceSel == sp ? Color.pkDark : Color.pkBorder))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
                .padding(.bottom, 16)

                Text(appState.priceSel.uppercased()).font(.system(size: 18, weight: .bold)).tracking(0.4)
                Text("Today's Fair Range").font(.system(size: 13)).foregroundColor(.pkSub).padding(.bottom, 12)

                HStack(alignment: .lastTextBaseline, spacing: 6) {
                    Text("₱\(f.low) – ₱\(f.high)").font(.system(size: 26, weight: .bold)).foregroundColor(.pkDark)
                    Text("/ kg").font(.system(size: 14)).foregroundColor(.pkSub)
                }
                .padding(.bottom, 16)

                HStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Average").font(.system(size: 13)).foregroundColor(.pkSub)
                        Text("₱\(f.mid)").font(.system(size: 17, weight: .bold))
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("This Week").font(.system(size: 13)).foregroundColor(.pkSub)
                        HStack(spacing: 4) {
                            Image(systemName: f.week >= 0 ? "arrow.up.right" : "arrow.down.right").font(.system(size: 12))
                            Text("\(String(format: "%.1f", f.week))%").font(.system(size: 17, weight: .bold))
                        }
                        .foregroundColor(f.week >= 0 ? .pkSuccess : .pkDanger)
                    }
                }
                .padding(.bottom, 16)

                VStack(alignment: .leading, spacing: 8) {
                    SparklineChart(data: f.history, color: .pkDark)
                    Text("Last 7 days").font(.system(size: 13)).foregroundColor(.pkSub)
                }
                .padding(16)
                .background(Color.pkSurface).overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.pkBorder))
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .padding(.bottom, 16)

                LabelCaps(text: "Recent Regional Transactions").padding(.bottom, 8)
                FlowChips(values: f.history).padding(.bottom, 16)

                InfoBox(
                    text: "Based on recent completed Palakaya transactions and available market references. Not an official government-mandated price.",
                    light: true,
                    extra: "Data confidence: High"
                )
            }
            .padding(.horizontal, 20).padding(.bottom, 28)
        }
        .background(Color.pkBg)
        .navigationTitle("Fair Prices")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Simple wrapping "chip" layout for the transaction price pills.
struct FlowChips: View {
    var values: [Int]
    var body: some View {
        FlexibleLayout(spacing: 8) {
            ForEach(values, id: \.self) { v in
                Text("₱\(v)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.pkText)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.pkBorder))
            }
        }
    }
}

/// Minimal flow/wrap layout using the Layout protocol.
struct FlexibleLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0; y += rowHeight + spacing; rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: maxWidth, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x: CGFloat = bounds.minX, y: CGFloat = bounds.minY, rowHeight: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX; y += rowHeight + spacing; rowHeight = 0
            }
            sub.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
