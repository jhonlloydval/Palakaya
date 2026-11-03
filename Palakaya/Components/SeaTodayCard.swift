import SwiftUI

/// Home card: today's sea and weather for the fisher's town. The sky colour follows the conditions
/// and the waves at the bottom rise and move with the real wave and wind forecast.
struct SeaTodayCard: View {
    var municipality: String
    var province: String
    @State private var conditions: SeaConditions?
    @State private var failed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("seaTodayExpanded") private var expanded = false

    var body: some View {
        ZStack(alignment: .bottom) {
            sky
            if let c = conditions {
                LiveSea(waveHeight: c.waveMax ?? 0.3, wind: c.windMax, animated: !reduceMotion)
                    .frame(height: expanded ? 92 : 44)
            }
            VStack(alignment: .leading, spacing: 0) {
                if let c = conditions {
                    if expanded { header; content(c) } else { compact(c) }
                } else {
                    header
                    placeholder
                }
            }
            .padding(expanded ? 20 : 16)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            guard conditions != nil else { return }
            withAnimation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.85)) { expanded.toggle() }
        }
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(color: Color(hex: "01447E").opacity(0.18), radius: 18, y: 10)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilitySummary)
        .accessibilityHint(expanded ? "Double tap to show less" : "Double tap to show details")
        .accessibilityAddTraits(.isButton)
        .task(id: municipality + province) { await load() }
    }

    // MARK: Pieces

    private var sky: some View {
        let colors: [Color]
        switch conditions?.verdict {
        case .stayAshore?: colors = [Color(hex: "1E2B3C"), Color(hex: "3D4B63")]
        case .careful?: colors = [Color(hex: "2F5577"), Color(hex: "5F86A6")]
        default: colors = [Color(hex: "0261A7"), Color(hex: "1FA6C9")]
        }
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    /// One row: temperature, sky, place and the verdict, with room for the waves underneath.
    private func compact(_ c: SeaConditions) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: c.sky.symbol)
                    .symbolRenderingMode(.hierarchical)
                    .font(.system(size: 28))
                    .foregroundColor(.white)
                Text("\(Int(c.temperature.rounded()))° · Sea today")
                    .font(.system(size: 18, weight: .bold, design: .rounded)).foregroundColor(.white)
                Spacer(minLength: 4)
                verdictPill(c.verdict)
            }
            Text("\(c.place) · waves \(c.waveMax.map { String(format: "%.1f m", $0) } ?? "–") · wind \(Int(c.windMax.rounded())) km/h · rain \(c.rainChance)%")
                .font(.system(size: 13.5, weight: .medium)).foregroundColor(.white.opacity(0.88))
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 4) {
                Text("Tap for details").font(.system(size: 12, weight: .medium))
                Image(systemName: "chevron.down").font(.system(size: 10, weight: .bold))
            }
            .foregroundColor(.white.opacity(0.75))
            .padding(.bottom, 22)
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Sea today").font(.system(size: 15, weight: .semibold)).foregroundColor(.white.opacity(0.85))
                Text(conditions?.place ?? (municipality.isEmpty ? provinceName(province) : municipality))
                    .font(.system(size: 13)).foregroundColor(.white.opacity(0.7))
            }
            Spacer()
            if let c = conditions {
                verdictPill(c.verdict)
                Image(systemName: "chevron.up").font(.system(size: 12, weight: .bold)).foregroundColor(.white.opacity(0.8))
            }
        }
    }

    private func content(_ c: SeaConditions) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 14) {
                Text("\(Int(c.temperature.rounded()))°")
                    .font(.system(size: 64, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                VStack(alignment: .leading, spacing: 4) {
                    Image(systemName: c.sky.symbol)
                        .symbolRenderingMode(.hierarchical)
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                    Text(c.sky.label).font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                }
            }
            .padding(.top, 6)

            Text(advice(c)).font(.system(size: 15, weight: .medium)).foregroundColor(.white.opacity(0.92))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 14)

            HStack(spacing: 0) {
                metric("Waves", c.waveMax.map { String(format: "%.1f m", $0) } ?? "–", "water.waves")
                divider
                metric("Wind", "\(Int(c.windMax.rounded())) km/h", "wind")
                divider
                metric("Rain", "\(c.rainChance)%", "cloud.rain.fill")
            }
            .padding(.vertical, 12)
            .background(.ultraThinMaterial.opacity(0.55))
            .environment(\.colorScheme, .dark)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            if let rise = c.sunrise, let set = c.sunset {
                DaylightTrack(sunrise: rise, sunset: set).padding(.top, 14)
            }

            Text("A guide only. Always follow PAGASA gale warnings and the Coast Guard.")
                .font(.system(size: 11.5)).foregroundColor(.white.opacity(0.75))
                .padding(.top, 12)
                .padding(.bottom, 56)
        }
    }

    private var placeholder: some View {
        Group {
            if failed {
                Text(municipality.isEmpty && province.isEmpty
                     ? "Add your municipality in Profile to see the sea forecast for your town."
                     : "Can't load the forecast right now. It needs an internet connection.")
            } else {
                HStack(spacing: 8) { ProgressView().tint(.white); Text("Checking the sea…") }
            }
        }
        .font(.system(size: 15, weight: .medium))
        .foregroundColor(.white.opacity(0.9))
        .padding(.top, 18).padding(.bottom, 8)
    }

    private var divider: some View { Rectangle().fill(Color.white.opacity(0.25)).frame(width: 1, height: 34) }

    private func metric(_ label: String, _ value: String, _ icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 15)).foregroundColor(.white.opacity(0.85))
            Text(value).font(.system(size: 17, weight: .bold, design: .rounded)).foregroundColor(.white)
                .minimumScaleFactor(0.8).lineLimit(1)
            Text(label).font(.system(size: 12)).foregroundColor(.white.opacity(0.75))
        }
        .frame(maxWidth: .infinity)
    }

    private func verdictPill(_ verdict: SeaConditions.Verdict) -> some View {
        let (text, icon, color): (String, String, Color) = switch verdict {
        case .good: ("Good to go", "checkmark.circle.fill", .pkSuccess)
        case .careful: ("Be careful", "exclamationmark.triangle.fill", .pkWarning)
        case .stayAshore: ("Stay ashore", "xmark.octagon.fill", .pkDanger)
        }
        return HStack(spacing: 5) {
            Image(systemName: icon).foregroundColor(color)
            Text(text).foregroundColor(Color(hex: "10272D"))
        }
        .font(.system(size: 13, weight: .bold))
        .padding(.horizontal, 12).frame(minHeight: 32)
        .background(Color.white)
        .clipShape(Capsule())
    }

    private func advice(_ c: SeaConditions) -> String {
        switch c.verdict {
        case .good: return "Calm enough for small boats. Have a good trip."
        case .careful:
            if c.rainChance >= 80 { return "Rain likely today. Bring cover and stay near shore." }
            return "Choppy at times. Stay near shore and watch the sky."
        case .stayAshore: return "Strong wind or high waves. Small boats should stay ashore today."
        }
    }

    private var accessibilitySummary: String {
        guard let c = conditions else { return "Sea today. Loading the forecast." }
        let verdict = switch c.verdict { case .good: "Good to go"; case .careful: "Be careful"; case .stayAshore: "Stay ashore" }
        return "Sea today in \(c.place): \(verdict). \(Int(c.temperature.rounded())) degrees, \(c.sky.label). "
            + "Waves up to \(c.waveMax.map { String(format: "%.1f", $0) } ?? "unknown") meters, wind \(Int(c.windMax)) kilometers per hour, \(c.rainChance) percent chance of rain."
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
}

/// Wave layers whose height follows the forecast wave height and whose speed follows the wind.
private struct LiveSea: View {
    var waveHeight: Double
    var wind: Double
    var animated: Bool

    var body: some View {
        let amplitude = CGFloat(min(4 + waveHeight * 9, 20))
        let speed = 0.3 + min(wind, 50) / 60
        TimelineView(.animation(paused: !animated)) { context in
            let t = animated ? context.date.timeIntervalSinceReferenceDate * speed : 0
            ZStack(alignment: .bottom) {
                Wave(phase: t, amplitude: amplitude, baseline: 0.35).fill(Color.white.opacity(0.12))
                Wave(phase: t * 1.3 + 2, amplitude: amplitude * 0.8, baseline: 0.55).fill(Color.pkAqua.opacity(0.28))
                Wave(phase: t * 1.7 + 4, amplitude: amplitude * 0.6, baseline: 0.75).fill(Color.white.opacity(0.16))
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Sunrise to sunset, with the sun placed at the current time.
private struct DaylightTrack: View {
    var sunrise: Date
    var sunset: Date

    var body: some View {
        let progress = max(0, min(1, Date().timeIntervalSince(sunrise) / sunset.timeIntervalSince(sunrise)))
        VStack(spacing: 6) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.25)).frame(height: 4)
                    Capsule().fill(Color(hex: "FFD66B")).frame(width: geo.size.width * progress, height: 4)
                    Circle().fill(Color(hex: "FFD66B")).frame(width: 14, height: 14)
                        .shadow(color: Color(hex: "FFD66B").opacity(0.8), radius: 6)
                        .offset(x: geo.size.width * progress - 7)
                }
                .frame(maxHeight: .infinity)
            }
            .frame(height: 14)
            HStack {
                Label(sunrise.formatted(date: .omitted, time: .shortened), systemImage: "sunrise.fill")
                Spacer()
                Label(sunset.formatted(date: .omitted, time: .shortened), systemImage: "sunset.fill")
            }
            .font(.system(size: 12.5, weight: .medium))
            .foregroundColor(.white.opacity(0.85))
        }
    }
}
