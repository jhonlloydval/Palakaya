import SwiftUI

/// Home card: today's sea and weather for the fisher's town, with a plain go / careful / stay verdict.
struct SeaTodayCard: View {
    var municipality: String
    var province: String
    @State private var conditions: SeaConditions?
    @State private var failed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Sea today").font(.system(size: 17, weight: .bold)).foregroundColor(.pkText)
                Spacer()
                if let c = conditions { verdictBadge(c.verdict) }
            }

            if let c = conditions {
                HStack(spacing: 10) {
                    Image(systemName: c.sky.symbol).symbolRenderingMode(.hierarchical).foregroundColor(.pkDark).font(.system(size: 30))
                    VStack(alignment: .leading, spacing: 1) {
                        Text("\(Int(c.temperature.rounded()))°C, \(c.sky.label)").font(.system(size: 16, weight: .semibold)).foregroundColor(.pkText)
                        Text(c.place).font(.system(size: 13)).foregroundColor(.pkSub)
                    }
                }
                HStack(spacing: 8) {
                    stat("Waves", c.waveMax.map { String(format: "up to %.1f m", $0) } ?? "No sea data", "water.waves")
                    stat("Wind", "\(Int(c.windMax.rounded())) km/h", "wind")
                    stat("Rain", "\(c.rainChance)%", "cloud.rain")
                }
                if let rise = c.sunrise, let set = c.sunset {
                    Text("Sunrise \(rise.formatted(date: .omitted, time: .shortened)) · Sunset \(set.formatted(date: .omitted, time: .shortened))")
                        .font(.system(size: 13)).foregroundColor(.pkSub)
                }
                Text("A guide only. Always follow PAGASA gale warnings and the Coast Guard.")
                    .font(.system(size: 12)).foregroundColor(.pkSub)
            } else if failed {
                Text(municipality.isEmpty && province.isEmpty
                     ? "Add your municipality in Profile to see the sea forecast for your town."
                     : "Can't load the forecast right now. It needs an internet connection.")
                    .font(.system(size: 14)).foregroundColor(.pkSub)
            } else {
                HStack(spacing: 8) { ProgressView(); Text("Checking the forecast…").font(.system(size: 14)).foregroundColor(.pkSub) }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.pkSurface)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.pkBorder))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .accessibilityElement(children: .combine)
        .task(id: municipality + province) { await load() }
    }

    private func load() async {
        guard !(municipality.isEmpty && province.isEmpty) else { failed = true; return }
        do {
            conditions = try await WeatherService.today(municipality: municipality, province: province)
            failed = false
        } catch {
            failed = conditions == nil
        }
    }

    private func stat(_ label: String, _ value: String, _ icon: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Label(label, systemImage: icon).font(.system(size: 12.5)).foregroundColor(.pkSub)
            Text(value).font(.system(size: 15, weight: .bold)).foregroundColor(.pkText).minimumScaleFactor(0.8).lineLimit(1)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.pkSurface2)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func verdictBadge(_ verdict: SeaConditions.Verdict) -> some View {
        switch verdict {
        case .good: return Badge(tone: .success, text: "GOOD TO GO", systemImage: "checkmark")
        case .careful: return Badge(tone: .warning, text: "BE CAREFUL", systemImage: "exclamationmark.triangle.fill")
        case .stayAshore: return Badge(tone: .danger, text: "STAY ASHORE", systemImage: "xmark.octagon.fill")
        }
    }
}
