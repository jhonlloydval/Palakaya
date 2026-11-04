import SwiftUI

struct PriceExplorerView: View {
    @Environment(AppState.self) private var appState
    @State private var search = ""
    /// Province name ("Quezon"), or nil for all of the Philippines.
    @State private var area: String?
    @State private var didSetArea = false

    private var species: [String] {
        let all = Set(ALL_SPECIES).union(FairPriceService.live.keys)
        let sorted = all.sorted()
        let q = search.trimmingCharacters(in: .whitespaces)
        return q.isEmpty ? sorted : sorted.filter { $0.localizedCaseInsensitiveContains(q) }
    }

    private var areas: [String] {
        var names = Set(COASTAL_PROVINCES).union(FairPriceService.provincesWithData)
        let mine = provinceName(appState.currentUserProvince)
        if !mine.isEmpty { names.insert(mine) }
        return names.sorted()
    }

    var body: some View {
        @Bindable var appState = appState
        let selected = species.contains(appState.priceSel) ? appState.priceSel : (species.first ?? appState.priceSel)
        let result = fairPrice(for: selected, province: area)

        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass").foregroundColor(.pkSub)
                    TextField("Search fish", text: $search)
                        .font(.system(size: 16))
                        .autocorrectionDisabled()
                    if !search.isEmpty {
                        Button { search = "" } label: { Image(systemName: "xmark.circle.fill").foregroundColor(.pkSub) }
                            .accessibilityLabel("Clear search")
                    }
                }
                .padding(.horizontal, 14).padding(.vertical, 12)
                .background(Color.pkSurface).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.pkBorder))
                .clipShape(RoundedRectangle(cornerRadius: 12)).padding(.bottom, 12)

                Menu {
                    Button { area = nil } label: { Label("All of the Philippines", systemImage: area == nil ? "checkmark" : "globe.asia.australia") }
                    Divider()
                    ForEach(areas, id: \.self) { name in
                        Button { area = name } label: {
                            if area == name { Label(name, systemImage: "checkmark") }
                            else if FairPriceService.provincesWithData.contains(name) { Label(name, systemImage: "chart.bar.fill") }
                            else { Text(name) }
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "mappin.circle.fill").font(.system(size: 15))
                        Text(area ?? "All of the Philippines").font(.system(size: 15, weight: .semibold))
                        Image(systemName: "chevron.down").font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(.pkDark)
                    .padding(.horizontal, 14).frame(minHeight: 40)
                    .background(Color.pkSurface2)
                    .clipShape(Capsule())
                }
                .accessibilityLabel("Location: \(area ?? "All of the Philippines"). Double tap to change.")
                .padding(.bottom, 14)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(species, id: \.self) { sp in
                            Button { appState.priceSel = sp } label: {
                                Text(sp)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(selected == sp ? .white : .pkText)
                                    .padding(.horizontal, 16).frame(minHeight: 40)
                                    .background(selected == sp ? Color.pkDark : Color.clear)
                                    .overlay(Capsule().stroke(selected == sp ? Color.pkDark : Color.pkBorder))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
                .padding(.bottom, 20)

                if species.isEmpty {
                    Text("No fish found with that name. Prices show here once a fish has been sold in Palakaya or has a regional estimate.")
                        .font(.system(size: 15)).foregroundColor(.pkSub)
                } else if let (f, source) = result {
                    priceCard(selected, f, source)
                }
            }
            .padding(.horizontal, 20).padding(.bottom, 28)
        }
        .background(Color.pkBg)
        .navigationTitle("Fair Prices")
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
        .onAppear {
            guard !didSetArea else { return }
            didSetArea = true
            let mine = provinceName(appState.currentUserProvince)
            area = mine.isEmpty ? nil : mine
        }
        .refreshable { await FairPriceService.refresh() }
    }

    @ViewBuilder
    private func priceCard(_ name: String, _ f: FairPriceInfo, _ source: FairPriceSource) -> some View {
        Text(name).font(.system(size: 24, weight: .bold)).foregroundColor(.pkText)
        Text(area.map { "Fair price in \($0)" } ?? "Fair price nationwide").font(.system(size: 15)).foregroundColor(.pkSub)
            .padding(.bottom, 10)

        HStack(alignment: .lastTextBaseline, spacing: 6) {
            Text("₱\(f.low) – ₱\(f.high)").font(.system(size: 32, weight: .heavy)).foregroundColor(.pkDark)
            Text("per kg").font(.system(size: 15)).foregroundColor(.pkSub)
        }
        .padding(.bottom, 16)

        HStack(spacing: 28) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Middle price").font(.system(size: 14)).foregroundColor(.pkSub)
                Text("₱\(f.mid)").font(.system(size: 19, weight: .bold))
            }
            if case .estimate = source {
                VStack(alignment: .leading, spacing: 2) {
                    Text("This week").font(.system(size: 14)).foregroundColor(.pkSub)
                    HStack(spacing: 4) {
                        Image(systemName: f.week >= 0 ? "arrow.up.right" : "arrow.down.right").font(.system(size: 13))
                        Text("\(String(format: "%.1f", abs(f.week)))% \(f.week >= 0 ? "up" : "down")").font(.system(size: 19, weight: .bold))
                    }
                    .foregroundColor(f.week >= 0 ? .pkSuccess : .pkDanger)
                }
            } else if let n = f.saleCount {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Sales counted").font(.system(size: 14)).foregroundColor(.pkSub)
                    Text("\(n)").font(.system(size: 19, weight: .bold))
                }
            }
        }
        .padding(.bottom, 16)

        if case .estimate = source {
            VStack(alignment: .leading, spacing: 8) {
                SparklineChart(data: f.history, color: .pkDark)
                Text("Estimated daily average, last 7 days").font(.system(size: 13)).foregroundColor(.pkSub)
            }
            .padding(16)
            .background(Color.pkSurface).overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.pkBorder))
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .padding(.bottom, 16)
        }

        if let area, !source.isRegional {
            InfoBox(text: "Not enough sales in \(area) yet, so this shows the \(FairPriceService.live[name] != nil ? "nationwide price from Palakaya sales" : "regional estimate").")
                .padding(.bottom, 12)
        }

        InfoBox(text: source.explanation + " This is a guide, not an official government price.",
                light: true, extra: "Confidence: \(source.confidence)")
        if let updated = FairPriceService.lastRefresh {
            Text("Updated \(updated.formatted(date: .abbreviated, time: .shortened)). Pull down to refresh.")
                .font(.system(size: 13)).foregroundColor(.pkSub).padding(.top, 10)
        }
    }
}
