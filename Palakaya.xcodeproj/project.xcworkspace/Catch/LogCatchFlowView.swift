import SwiftUI
import SwiftData

struct LogCatchFlowView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        @Bindable var appState = appState
        NavigationStack {
            Group {
                switch appState.lcStep {
                case 1: speciesStep
                case 2: detailsStep
                default: reviewStep
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            .navigationTitle("Log Catch · \(appState.lcStep) of 3")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        if appState.lcStep == 1 { dismiss(); appState.resetLogCatch() }
                        else { appState.lcStep -= 1 }
                    } label: { Image(systemName: "chevron.left") }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { dismiss(); appState.resetLogCatch() } label: { Image(systemName: "xmark") }
                }
            }
        }
    }

    private var speciesStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("What did you catch?").font(.system(size: 20, weight: .bold)).padding(.bottom, 4)
                Text("Search or pick from your recent species.").font(.system(size: 13)).foregroundColor(.pkSub).padding(.bottom, 16)

                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass").foregroundColor(.pkSub)
                    Text("Search fish species").foregroundColor(.pkSub).font(.system(size: 14))
                }
                .padding(.horizontal, 14).padding(.vertical, 11)
                .background(Color.pkSurface).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.pkBorder))
                .clipShape(RoundedRectangle(cornerRadius: 12)).padding(.bottom, 12)

                LabelCaps(text: "Recent Species").padding(.bottom, 8)
                speciesGrid(RECENT_SPECIES, other: false)
                    .padding(.bottom, 12)
                speciesGrid(ALL_SPECIES.filter { !RECENT_SPECIES.contains($0) }, other: true)
            }
        }
    }

    private func speciesGrid(_ species: [String], other: Bool) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(species, id: \.self) { sp in
                Button {
                    appState.lcSpecies = sp
                    appState.lcStep = 2
                } label: {
                    Text(sp)
                        .font(.system(size: 14, weight: other ? .medium : .semibold))
                        .foregroundColor(.pkText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(other ? Color.clear : Color.pkSurface)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.pkBorder))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var detailsStep: some View {
        @Bindable var appState = appState
        return ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Catch details").font(.system(size: 20, weight: .bold)).padding(.bottom, 4)
                Text(appState.lcSpecies ?? "").font(.system(size: 13)).foregroundColor(.pkSub).padding(.bottom, 16)

                HStack {
                    TextField("0.0", text: $appState.lcWeight)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 18, weight: .semibold))
                    Text("kg").foregroundColor(.pkSub)
                }
                .padding(.horizontal, 14).padding(.vertical, 12)
                .background(Color.pkSurface).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.pkBorder))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .pkField("Weight (kg)")

                PKTextField(text: $appState.lcGround).pkField("Fishing Ground")

                HStack {
                    Image(systemName: "calendar").foregroundColor(.pkSub)
                    Text("Today, 6:45 AM").foregroundColor(.pkText)
                }
                .padding(.horizontal, 14).padding(.vertical, 12)
                .background(Color.pkSurface2)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .pkField("Date & Time")

                Button {
                    appState.lcPhoto.toggle()
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: "camera").font(.system(size: 20)).foregroundColor(.pkSub)
                        Text(appState.lcPhoto ? "Photo added" : "Tap to add a photo").font(.system(size: 12.5)).foregroundColor(.pkSub)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(24)
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [6])).foregroundColor(Color.pkBorder))
                }
                .buttonStyle(.plain)
                .pkField("Photo of Catch (optional)")

                PrimaryButton(title: "Review Catch", isDisabled: (Double(appState.lcWeight) ?? 0) <= 0) {
                    appState.lcStep = 3
                }
                .padding(.top, 4)
            }
        }
    }

    private var reviewStep: some View {
        let weight = Double(appState.lcWeight) ?? 0
        let fair = appState.lcSpecies.flatMap { FAIR_DB[$0] }
        return ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Review").font(.system(size: 20, weight: .bold)).padding(.bottom, 16)

                CardContainer {
                    Text(appState.lcSpecies ?? "").font(.system(size: 18, weight: .bold))
                    Text("\(weight.pkTrimmed) kg").font(.system(size: 13)).foregroundColor(.pkSub).padding(.bottom, 8)
                    HStack(spacing: 4) { Image(systemName: "mappin.circle.fill").font(.system(size: 12)); Text(appState.lcGround).font(.system(size: 13)) }
                        .foregroundColor(.pkSub)
                    HStack(spacing: 4) { Image(systemName: "clock").font(.system(size: 12)); Text("Today · 6:45 AM").font(.system(size: 13)) }
                        .foregroundColor(.pkSub)
                }
                .padding(.bottom, 16)

                if let fair {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Fair Price").font(.system(size: 13)).foregroundColor(.pkSub)
                        Text("₱\(fair.low)–₱\(fair.high)/kg").font(.system(size: 18, weight: .bold)).foregroundColor(.pkDark).padding(.bottom, 8)
                        Text("Potential Value").font(.system(size: 13)).foregroundColor(.pkSub)
                        Text("₱\(Int(weight * Double(fair.low)).formatted())–₱\(Int(weight * Double(fair.high)).formatted())")
                            .font(.system(size: 20, weight: .bold)).foregroundColor(.pkText)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.pkSurface2)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .padding(.bottom, 24)
                }

                PrimaryButton(title: "Save & List for Sale") { save(andList: true) }
                GhostButton(title: "Save Catch") { save(andList: false) }
                    .padding(.top, 12)
            }
        }
    }

    private func save(andList: Bool) {
        guard let species = appState.lcSpecies else { return }
        let weight = Double(appState.lcWeight) ?? 0
        let record = CatchRecord(species: species, weight: weight, ground: appState.lcGround, timeLabel: "6:45 AM")
        modelContext.insert(record)
        try? modelContext.save()

        appState.activeCatchID = record.id
        appState.resetLogCatch()
        dismiss()

        appState.path = NavigationPath()
        appState.path.append(Route.catchDetails(record.id))
        if andList {
            appState.listPrice = String(FAIR_DB[species]?.mid ?? 0)
            appState.listingQty = "\(weight.pkTrimmed) kg"
            appState.path.append(Route.createListing(record.id))
        }
    }
}
