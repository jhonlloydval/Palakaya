import SwiftUI
import SwiftData

struct RecordSaleView: View {
    var catchID: UUID
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query private var catches: [CatchRecord]
    private var record: CatchRecord? { catches.first { $0.id == catchID } }
    @State private var isSaving = false

    var body: some View {
        @Bindable var appState = appState
        if let c = record, let b = appState.selectedBuyer {
            let quantity = b.quantity ?? c.weight
            let total = Int(quantity * Double(b.offer))
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    infoRow("Catch", "\(c.species) · \(c.weight.pkTrimmed) kg")
                    infoRow("Buyer", b.name)

                    HStack(spacing: 12) {
                        detailBox("Agreed Price", "₱\(b.offer)/kg")
                        detailBox("Quantity Sold", "\(quantity.pkTrimmed) kg")
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

                    InfoBox(text: b.offerID != nil
                            ? "The buyer pays in the app (GCash, Maya or LandBank, demo). You'll get a notification once paid."
                            : "Confirm payment and pickup arrangements directly with the buyer.")
                        .padding(.bottom, 24)

                    PrimaryButton(title: "Complete Sale") {
                        complete(c, buyer: b)
                    }
                    .disabled(isSaving)
                }
                .padding(.horizontal, 20).padding(.bottom, 28)
            }
            .background(Color.pkBg)
            .navigationTitle("Record Sale")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    /// Accepts the buyer's real offer (if any) in the cloud, then records the sale on the phone.
    private func complete(_ c: CatchRecord, buyer b: Buyer) {
        isSaving = true
        Task {
            defer { isSaving = false }
            if let offerID = b.offerID, let offer = appState.myOffers.first(where: { $0.id == offerID }) {
                do {
                    try await OfferController.respond(to: offer, accept: true, appState: appState)
                } catch {
                    appState.errorMessage = error.localizedDescription
                    return
                }
            }
            do {
                appState.saleResult = try CatchController(context: modelContext).completeSale(c, buyer: b)
            } catch {
                appState.errorMessage = "Your sale could not be recorded. Please try again."
                return
            }
            await SyncController.sync(appState: appState, context: modelContext)
            appState.path.append(Route.saleRecorded)
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
