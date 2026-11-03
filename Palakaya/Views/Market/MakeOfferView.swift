import SwiftUI

/// Buyer sends a price offer for another fisher's listed catch.
struct MakeOfferView: View {
    var listing: OtherListing
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var price = ""
    @State private var quantity = ""
    @State private var message = ""
    @State private var isSending = false
    @State private var error: String?

    private var priceValue: Double? { Double(price.replacingOccurrences(of: ",", with: ".")).flatMap { $0 > 0 ? $0 : nil } }
    private var quantityValue: Double? {
        InputParsing.weightKg(quantity).flatMap { $0 <= listing.weight ? $0 : nil }
    }
    private var total: Int { Int(((priceValue ?? 0) * (quantityValue ?? 0)).rounded()) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text("\(listing.species) · \(listing.weight.pkTrimmed) kg from \(listing.seller)")
                        .font(.system(size: 14, weight: .semibold)).padding(.bottom, 4)
                    Text("Asking price ₱\(listing.price)/kg").font(.system(size: 13)).foregroundColor(.pkSub)
                        .padding(.bottom, 16)

                    HStack {
                        Text("₱").font(.system(size: 16, weight: .semibold)).foregroundColor(.pkSub)
                        TextField("0", text: $price).keyboardType(.decimalPad).font(.system(size: 18, weight: .semibold))
                        Text("/kg").foregroundColor(.pkSub)
                    }
                    .padding(.horizontal, 14).padding(.vertical, 12)
                    .frame(minHeight: 48)
                    .background(Color.pkSurface).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.pkBorder))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .pkField("Your Offer (₱ / kg)")

                    if let fair = FAIR_DB[listing.species], let p = priceValue {
                        let below = p < Double(fair.low)
                        InfoBox(text: below
                            ? "This is below the fair price of ₱\(fair.low)–₱\(fair.high)/kg. Fishers are more likely to accept a fair offer."
                            : "Within or above the fair price of ₱\(fair.low)–₱\(fair.high)/kg.")
                            .padding(.bottom, 16)
                    }

                    HStack {
                        TextField("0", text: $quantity).keyboardType(.decimalPad).font(.system(size: 18, weight: .semibold))
                        Text("kg of \(listing.weight.pkTrimmed)").foregroundColor(.pkSub)
                    }
                    .padding(.horizontal, 14).padding(.vertical, 12)
                    .frame(minHeight: 48)
                    .background(Color.pkSurface).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.pkBorder))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .pkField("Quantity")

                    PKTextField(placeholder: "e.g. Pickup today 4 PM, I bring ice", text: $message)
                        .pkField("Message to the fisher (optional)")

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total if accepted").font(.system(size: 13)).foregroundColor(.pkSub)
                        Text("₱\(total.formatted())").font(.system(size: 24, weight: .bold)).foregroundColor(.pkDark)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.pkSurface2)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .padding(.bottom, 16)

                    if let error {
                        Text(error).font(.system(size: 12.5)).foregroundColor(.pkDanger).padding(.bottom, 8)
                    }

                    PrimaryButton(title: isSending ? "Sending…" : "Send Offer",
                                  isDisabled: priceValue == nil || quantityValue == nil || isSending) {
                        send()
                    }
                    Text("You pay through Palakaya only after the fisher accepts.")
                        .font(.system(size: 12)).foregroundColor(.pkSub).padding(.top, 8)
                }
                .padding(20)
            }
            .background(Color.pkBg)
            .navigationTitle("Make an Offer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
            .onAppear {
                if price.isEmpty { price = String(listing.price) }
                if quantity.isEmpty { quantity = listing.weight.pkTrimmed }
            }
        }
    }

    private func send() {
        guard let p = priceValue, let q = quantityValue, let catchID = UUID(uuidString: listing.id) else { return }
        isSending = true
        error = nil
        Task {
            defer { isSending = false }
            do {
                try await OfferController.makeOffer(catchID: catchID, pricePerKg: p, quantityKg: q,
                                                    message: message, appState: appState)
                dismiss()
            } catch {
                self.error = error.localizedDescription
            }
        }
    }
}
