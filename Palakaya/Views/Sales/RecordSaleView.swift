import SwiftUI
import SwiftData

struct RecordSaleView: View {
    var catchID: UUID
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query private var catches: [CatchRecord]
    private var record: CatchRecord? { catches.first { $0.id == catchID } }

    var body: some View {
        @Bindable var appState = appState
        if let c = record, let b = appState.selectedBuyer {
            let total = Int(c.weight * Double(b.offer))
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    infoRow("Catch", "\(c.species) · \(c.weight.pkTrimmed) kg")
                    infoRow("Buyer", b.name)

                    HStack(spacing: 12) {
                        detailBox("Agreed Price", "₱\(b.offer)/kg")
                        detailBox("Quantity Sold", "\(c.weight.pkTrimmed) kg")
                    }
                    .padding(.bottom, 16)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total").font(.system(size: 13)).foregroundColor(.pkSub)
                        Text("₱\(total.formatted())").font(.system(size: 24, weight: .bold)).foregroundColor(.pkDark)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.pkSurface2)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .padding(.bottom, 24)

                    InfoBox(text: "Palakaya does not handle payments. Confirm payment and pickup arrangements directly with the buyer.")
                        .padding(.bottom, 24)

                    PrimaryButton(title: "Complete Sale") {
                        guard let fair = c.fair else { return }
                        let amount = Int(c.weight * Double(b.offer))
                        let alignment = Int((Double(b.offer) / Double(fair.mid)) * 100)
                        c.status = .sold
                        c.price = Double(b.offer)
                        c.saleAmount = Double(amount)
                        c.buyerName = b.name
                        c.alignment = alignment
                        try? modelContext.save()
                        appState.saleResult = SaleResult(amount: amount, alignment: alignment, buyerName: b.name, species: c.species)
                        appState.path.append(Route.saleRecorded)
                    }
                }
                .padding(.horizontal, 20).padding(.bottom, 28)
            }
            .background(Color.pkBg)
            .navigationTitle("Record Sale")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.system(size: 13)).foregroundColor(.pkSub)
            Text(value).font(.system(size: 16, weight: .bold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.pkSurface).overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.pkBorder))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.bottom, 16)
    }

    private func detailBox(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.system(size: 13)).foregroundColor(.pkSub)
            Text(value).font(.system(size: 16, weight: .bold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.pkSurface).overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.pkBorder))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
