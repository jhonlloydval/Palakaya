import SwiftUI
import SwiftData

struct CatchDetailsView: View {
    var catchID: UUID
    @Environment(AppState.self) private var appState
    @Query private var catches: [CatchRecord]

    private var record: CatchRecord? { catches.first { $0.id == catchID } }

    var body: some View {
        @Bindable var appState = appState
        ScrollView {
            if let c = record {
                VStack(alignment: .leading, spacing: 0) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 18).fill(Color.pkSurface2).frame(height: 144)
                        Image(systemName: "water.waves").font(.system(size: 36)).foregroundColor(.pkAqua)
                    }
                    .padding(.bottom, 16)

                    Text(c.species).font(.system(size: 22, weight: .bold))
                    Text("Catch ID: \(c.id.uuidString.prefix(8).uppercased())").font(.system(size: 13)).foregroundColor(.pkSub).padding(.bottom, 16)

                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            detailBox("Weight", "\(c.weight.pkTrimmed) kg")
                            detailBox("Date / Time", "Today, \(c.timeLabel)")
                        }
                        detailBox("Fishing Ground", c.ground)
                    }
                    .padding(.bottom, 20)

                    if let fair = c.fair {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Fair Price").font(.system(size: 14, weight: .semibold)).foregroundColor(.pkDark)
                            HStack { Text("Regional benchmark").font(.system(size: 13)).foregroundColor(.pkSub); Spacer(); Text("₱\(fair.low)–₱\(fair.high)/kg").font(.system(size: 13.5, weight: .semibold)) }
                            HStack { Text("Current midpoint").font(.system(size: 13)).foregroundColor(.pkSub); Spacer(); Text("₱\(fair.mid)/kg").font(.system(size: 13.5, weight: .semibold)) }
                            Divider().overlay(Color.pkBorder)
                            HStack { Text("Potential value").font(.system(size: 13.5, weight: .semibold)); Spacer(); Text("₱\(Int(c.weight * Double(fair.mid)).formatted())").font(.system(size: 15, weight: .bold)).foregroundColor(.pkDark) }
                        }
                        .padding(16)
                        .background(Color.pkSurface2)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .padding(.bottom, 24)
                    }

                    if c.status == .sold {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Transaction").font(.system(size: 14, weight: .semibold))
                            HStack { Text("Buyer").foregroundColor(.pkSub); Spacer(); Text(c.buyerName ?? "").font(.system(size: 13.5, weight: .semibold)) }.font(.system(size: 13))
                            HStack { Text("Amount").foregroundColor(.pkSub); Spacer(); Text("₱\(Int(c.saleAmount ?? 0).formatted())").font(.system(size: 13.5, weight: .semibold)) }.font(.system(size: 13))
                        }
                        .padding(16)
                        .background(Color.pkSurface)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.pkBorder))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    } else if c.status == .listed {
                        HStack {
                            Text("Listed at ₱\(Int(c.price ?? 0))/kg").font(.system(size: 14, weight: .semibold))
                            Spacer()
                            Badge(tone: .success, text: "LISTED")
                        }
                        .padding(16)
                        .background(Color.pkSurface)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.pkBorder))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    } else {
                        PrimaryButton(title: "List Catch for Sale") {
                            appState.listPrice = String(c.fair?.mid ?? 0)
                            appState.listingQty = "\(c.weight.pkTrimmed) kg"
                            appState.path.append(Route.createListing(c.id))
                        }
                        GhostButton(title: "Edit Record") {}.padding(.top, 12)
                    }
                }
                .padding(.horizontal, 20).padding(.bottom, 28)
            }
        }
        .background(Color.pkBg)
        .navigationTitle("Catch Details")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func detailBox(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.system(size: 13)).foregroundColor(.pkSub)
            Text(value).font(.system(size: 16, weight: .bold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.pkSurface)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.pkBorder))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
