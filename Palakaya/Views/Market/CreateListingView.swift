import SwiftUI
import SwiftData

struct CreateListingView: View {
    var catchID: UUID
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query private var catches: [CatchRecord]

    private var record: CatchRecord? { catches.first { $0.id == catchID } }

    var body: some View {
        @Bindable var appState = appState
        if let c = record {
            let fair = c.fair
            let price = Double(appState.listPrice) ?? 0
            let status: (label: String, tone: Tone)? = fair.map { f in
                if price >= Double(f.low) { return ("Your price is within today's fair-price range.", .success) }
                let pct = Int(((Double(f.low) - price) / Double(f.low)) * 100)
                return pct <= 15 ? ("This is around \(pct)% below the current regional benchmark.", .warning)
                                  : ("This is around \(pct)% below the current regional benchmark.", .danger)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("\(c.species) · \(c.weight.pkTrimmed) kg").font(.system(size: 14, weight: .semibold))
                        Spacer()
                    }
                    .padding(12)
                    .background(Color.pkSurface).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.pkBorder))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .pkField("Selected Catch")

                    if let fair {
                        Text("Fair price range today: ₱\(fair.low)–₱\(fair.high)/kg")
                            .font(.system(size: 13)).foregroundColor(.pkSub).padding(.bottom, 16)
                    }

                    HStack {
                        Text("₱").font(.system(size: 16, weight: .semibold)).foregroundColor(.pkSub)
                        TextField("0", text: $appState.listPrice)
                            .keyboardType(.numberPad)
                            .font(.system(size: 18, weight: .semibold))
                        Text("/kg").foregroundColor(.pkSub)
                    }
                    .padding(.horizontal, 14).padding(.vertical, 12)
                    .background(Color.pkSurface).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.pkBorder))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .pkField("Your Price (₱ / kg)")

                    if let status {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "info.circle.fill").foregroundColor(status.tone.fg)
                            Text(status.label).font(.system(size: 12.5, weight: .medium)).foregroundColor(status.tone.fg)
                        }
                        .padding(14)
                        .background(status.tone.bg)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.bottom, 16)
                    }

                    PKTextField(text: $appState.listingQty).pkField("Available Quantity")
                    PKTextField(text: $appState.listingLocation).pkField("Landing Location")
                    PKTextField(text: $appState.listingPickup).pkField("Pickup Availability")
                    PKTextField(placeholder: "e.g. fresh catch, iced", text: $appState.listingNotes).pkField("Notes (optional)")

                    PrimaryButton(title: "Publish Listing", isDisabled: price <= 0) {
                        c.status = .listed
                        c.price = price
                        c.buyersInterested = 2
                        try? modelContext.save()
                        appState.path.append(Route.listingDetails(c.id))
                    }
                }
                .padding(.horizontal, 20).padding(.bottom, 28)
            }
            .background(Color.pkBg)
            .navigationTitle("Create Listing")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
