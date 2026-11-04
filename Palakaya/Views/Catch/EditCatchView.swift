import SwiftUI
import SwiftData

/// Edit or delete a catch that has not been listed or sold yet.
struct EditCatchView: View {
    var record: CatchRecord
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var species = ""
    @State private var weight = ""
    @State private var ground = ""
    @State private var date = Date()
    @State private var photo: Data?
    @State private var error: String?
    @State private var confirmDelete = false

    private var cleanSpecies: String { species.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var canSave: Bool { !cleanSpecies.isEmpty && InputParsing.weightKg(weight) != nil }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    PKTextField(placeholder: "e.g. Galunggong", text: $species).pkField("Fish")
                    HStack {
                        TextField("0.0", text: $weight).keyboardType(.decimalPad).font(.system(size: 18, weight: .semibold))
                        Text("kg").foregroundColor(.pkSub)
                    }
                    .padding(.horizontal, 14).padding(.vertical, 12)
                    .background(Color.pkSurface).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.pkBorder))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .pkField("Weight (kg)")
                    PKTextField(text: $ground).pkField("Fishing Ground")
                    DatePicker("", selection: $date, in: ...Date(), displayedComponents: [.date, .hourAndMinute])
                        .labelsHidden()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .pkField("Date & Time")
                    CatchPhotoPicker(photo: $photo).pkField("Photo of Catch (optional)")

                    if let error {
                        Text(error).font(.system(size: 13.5)).foregroundColor(.pkDanger).padding(.bottom, 8)
                    }
                    PrimaryButton(title: "Save changes", isDisabled: !canSave) { save() }

                    Button(role: .destructive) { confirmDelete = true } label: {
                        Label("Delete this catch", systemImage: "trash")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.pkDanger)
                            .frame(maxWidth: .infinity, minHeight: 52)
                    }
                    .padding(.top, 12)
                }
                .padding(20)
            }
            .background(Color.pkBg)
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Edit Catch")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
            .confirmationDialog("Delete this catch?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Delete", role: .destructive) { delete() }
            } message: {
                Text("It will be removed from this phone and from your cloud backup. This can't be undone.")
            }
            .onAppear {
                species = record.species
                weight = record.weight.pkTrimmed
                ground = record.ground
                date = record.dateLogged
                photo = record.photoData
            }
        }
    }

    private func save() {
        guard let kg = InputParsing.weightKg(weight) else { return }
        do {
            try CatchController(context: modelContext)
                .updateCatch(record, species: cleanSpecies, weight: kg, ground: ground, date: date, photo: photo)
            Task { await SyncController.sync(appState: appState, context: modelContext) }
            dismiss()
        } catch {
            self.error = "Your changes could not be saved. Please try again."
        }
    }

    private func delete() {
        do {
            try CatchController(context: modelContext).deleteCatch(record)
            Task { await SyncController.sync(appState: appState, context: modelContext) }
            dismiss()
            appState.path = NavigationPath()
        } catch {
            self.error = "This catch could not be deleted. Please try again."
        }
    }
}
