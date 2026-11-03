import SwiftUI

/// Receipt body for a paid offer, shared by the checkout's last step and the "View Receipt" sheet.
struct PaymentReceiptContent: View {
    let offer: Offer

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle().fill(Color.pkSuccessBg).frame(width: 72, height: 72)
                Image(systemName: "checkmark").font(.system(size: 28, weight: .black)).foregroundColor(.pkSuccess)
            }
            .padding(.bottom, 12)
            Text("₱\(offer.total.formatted())").font(.system(size: 32, weight: .bold))
            Text("Paid to \(offer.fisherFirstName)").font(.system(size: 14)).foregroundColor(.pkSub).padding(.bottom, 20)

            VStack(spacing: 10) {
                row("Item", "\(offer.species) · \(offer.quantityKg.pkTrimmed) kg")
                row("Price", "₱\(offer.pricePerKg.pkTrimmed)/kg")
                row("Paid with", offer.paymentMethod ?? "—")
                row("Reference no.", offer.paymentRef ?? "—")
                row("Date", (offer.paidAt ?? Date()).formatted(date: .abbreviated, time: .shortened))
                row("Buyer", offer.buyerName)
            }
            .padding(16)
            .background(Color.pkSurface)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.pkBorder))
            .clipShape(RoundedRectangle(cornerRadius: 16))

            Text("Demo transaction for presentation only. No real money was moved.")
                .font(.system(size: 12)).foregroundColor(.pkSub).multilineTextAlignment(.center).padding(.top, 14)
        }
        .frame(maxWidth: .infinity)
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(label).foregroundColor(.pkSub)
            Spacer()
            Text(value).fontWeight(.semibold).multilineTextAlignment(.trailing)
        }
        .font(.system(size: 14))
    }
}

struct PaymentReceiptView: View {
    let offer: Offer
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView { PaymentReceiptContent(offer: offer).padding(20) }
                .background(Color.pkBg)
                .navigationTitle("Receipt")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
}
