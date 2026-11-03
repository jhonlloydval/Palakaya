import SwiftUI

struct OnboardingSlide {
    var headline: String
    var sub: String
}

let onboardingSlides: [OnboardingSlide] = [
    OnboardingSlide(headline: "Know what your catch is worth",
                    sub: "Log each catch at the landing site and see a fair price before anyone names theirs."),
    OnboardingSlide(headline: "Sell straight to buyers near you",
                    sub: "List your catch and get offers from verified stalls, carinderias and cooperatives."),
    OnboardingSlide(headline: "Catch smarter, sell fairer",
                    sub: "Your own records and this week's local prices show you when and where to sell."),
]

/// First-run story. Each step shows a real piece of the app (a catch, a buyer, a price trend)
/// rising out of the sea, so the fisher sees what Palakaya does before signing up.
struct OnboardingView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isLast: Bool { appState.obStep == onboardingSlides.count - 1 }

    var body: some View {
        @Bindable var appState = appState

        ZStack {
            VStack(spacing: 0) {
                Spacer()
                SeaWaves(animated: !reduceMotion).frame(height: 250)
            }
            .background(Color.pkDeepSea)
            .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                TabView(selection: $appState.obStep) {
                    ForEach(onboardingSlides.indices, id: \.self) { i in
                        OnboardingPage(index: i, isActive: appState.obStep == i, reduceMotion: reduceMotion)
                            .tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                actions
            }
        }
        .fontDesign(.rounded)
    }

    private var topBar: some View {
        HStack {
            Image("PalakayaAppIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 34, height: 34)
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                .accessibilityHidden(true)
            Text("Palakaya")
                .font(.system(size: 19, weight: .bold))
                .foregroundColor(.white)
            Spacer()
            if !isLast {
                Button("Skip") { withAnimation { appState.obStep = onboardingSlides.count - 1 } }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(.horizontal, 24)
        .frame(height: 52)
    }

    private var actions: some View {
        VStack(spacing: 14) {
            StepMarker(count: onboardingSlides.count, current: appState.obStep)

            Button {
                if isLast { appState.phase = .register }
                else { withAnimation(.easeInOut(duration: 0.3)) { appState.obStep += 1 } }
            } label: {
                Text(isLast ? "Create my account" : "Next")
                    .font(.system(size: 17, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 54)
                    .background(Color.white)
                    .foregroundColor(Color(hex: "01447E"))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)

            Button { appState.phase = .login } label: {
                Text("I already have an account")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(minHeight: 44)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 12)
    }
}

private struct OnboardingPage: View {
    var index: Int
    var isActive: Bool
    var reduceMotion: Bool
    @State private var risen = false

    var body: some View {
        let slide = onboardingSlides[index]
        VStack(alignment: .leading, spacing: 0) {
            Spacer(minLength: 8)
            Group {
                switch index {
                case 0: CatchTicket()
                case 1: BuyerMatchTicket()
                default: PriceTrendTicket()
                }
            }
            .frame(maxWidth: .infinity)
            .offset(y: risen ? 0 : 40)
            .opacity(risen ? 1 : 0)
            Spacer(minLength: 20)

            Text(slide.headline)
                .font(.system(size: 30, weight: .heavy))
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 10)
            Text(slide.sub)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.82))
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
        .onAppear { rise() }
        .onChange(of: isActive) { _, active in
            if active { rise() } else if !reduceMotion { risen = false }
        }
    }

    /// The one entrance moment: the card surfaces from the waves when its step is shown.
    private func rise() {
        guard isActive else { return }
        if reduceMotion { risen = true; return }
        withAnimation(.spring(response: 0.55, dampingFraction: 0.78)) { risen = true }
    }
}

// MARK: - Step illustrations (built from the app's own screens and seed data)

private struct TicketCard<Content: View>: View {
    var tilt: Double
    @ViewBuilder var content: () -> Content
    var body: some View {
        VStack(alignment: .leading, spacing: 0) { content() }
            .padding(20)
            .frame(width: 290, alignment: .leading)
            .background(Color.pkSurface)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: .black.opacity(0.28), radius: 24, y: 14)
            .rotationEffect(.degrees(tilt))
    }
}

private struct CatchTicket: View {
    var body: some View {
        TicketCard(tilt: -3) {
            HStack {
                Text("Tulingan").font(.system(size: 22, weight: .heavy)).foregroundColor(.pkText)
                Spacer()
                Badge(tone: .success, text: "LISTED")
            }
            Text("18 kg from Batangas Bay, 6:05 AM")
                .font(.system(size: 13, weight: .medium)).foregroundColor(.pkSub)
                .padding(.bottom, 16)
            Text("Fair price today").font(.system(size: 13, weight: .semibold)).foregroundColor(.pkSub)
            Text("₱205 to ₱212 per kg").font(.system(size: 24, weight: .heavy)).foregroundColor(.pkDark)
            Text("Worth about ₱3,750 in total")
                .font(.system(size: 13, weight: .semibold)).foregroundColor(.pkSuccess)
                .padding(.top, 4)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct BuyerMatchTicket: View {
    var body: some View {
        TicketCard(tilt: 2.5) {
            Text("Offers on your Tulingan").font(.system(size: 13, weight: .semibold)).foregroundColor(.pkSub)
                .padding(.bottom, 12)
            buyer("Liza's Seafood Stall", "0.8 km away, offers ₱210/kg", best: true)
            Divider().overlay(Color.pkBorder).padding(.vertical, 10)
            buyer("Coastal Fresh Co-op", "2.1 km away, offers ₱206/kg", best: false)
        }
        .accessibilityElement(children: .combine)
    }

    private func buyer(_ name: String, _ detail: String, best: Bool) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(Color.pkSurface2).frame(width: 40, height: 40)
                Image(systemName: "storefront.fill").foregroundColor(.pkDark)
            }
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(name).font(.system(size: 15, weight: .bold)).foregroundColor(.pkText)
                    Image(systemName: "checkmark.seal.fill").font(.system(size: 12)).foregroundColor(.pkDark)
                }
                Text(detail).font(.system(size: 12.5, weight: .medium)).foregroundColor(best ? .pkSuccess : .pkSub)
            }
        }
    }
}

private struct PriceTrendTicket: View {
    var body: some View {
        TicketCard(tilt: -2) {
            HStack(alignment: .firstTextBaseline) {
                Text("Galunggong").font(.system(size: 15, weight: .bold)).foregroundColor(.pkText)
                Spacer()
                Text("up 4.2% this week").font(.system(size: 12.5, weight: .semibold)).foregroundColor(.pkSuccess)
            }
            Text("₱192/kg").font(.system(size: 30, weight: .heavy)).foregroundColor(.pkDark)
                .padding(.bottom, 6)
            SparklineChart(data: [176, 181, 179, 184, 186, 185, 192], color: .pkDark)
            Text("Best day to sell: Saturday morning")
                .font(.system(size: 13, weight: .semibold)).foregroundColor(.pkSub)
                .padding(.top, 8)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Sea and step marker

private struct StepMarker: View {
    var count: Int
    var current: Int
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { i in
                Capsule()
                    .fill(Color.white.opacity(i == current ? 1 : 0.35))
                    .frame(width: i == current ? 26 : 8, height: 8)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: current)
        .accessibilityElement()
        .accessibilityLabel("Step \(current + 1) of \(count)")
    }
}

/// Three layers of swell in the logo's teal and blues. They drift slowly unless Reduce Motion is on.
private struct SeaWaves: View {
    var animated: Bool

    var body: some View {
        TimelineView(.animation(paused: !animated)) { context in
            let t = animated ? context.date.timeIntervalSinceReferenceDate : 0
            ZStack(alignment: .bottom) {
                Wave(phase: t * 0.35, amplitude: 14, baseline: 0.30)
                    .fill(Color.pkAqua.opacity(0.22))
                Wave(phase: t * 0.5 + 1.8, amplitude: 11, baseline: 0.48)
                    .fill(Color(hex: "0261A7").opacity(0.55))
                Wave(phase: t * 0.7 + 3.1, amplitude: 9, baseline: 0.66)
                    .fill(Color(hex: "01447E"))
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct Wave: Shape {
    var phase: Double
    var amplitude: CGFloat
    /// Where the wave's resting line sits, as a fraction of the height from the top.
    var baseline: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let mid = rect.height * baseline
        path.move(to: CGPoint(x: 0, y: rect.maxY))
        stride(from: 0, through: rect.width, by: 4).forEach { x in
            let relative = Double(x / rect.width) * 2 * .pi * 1.3
            path.addLine(to: CGPoint(x: x, y: mid + amplitude * CGFloat(sin(relative + phase))))
        }
        path.addLine(to: CGPoint(x: rect.width, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

extension Color {
    /// The night-sea background behind the onboarding story, the same in Light and Dark Mode.
    static let pkDeepSea = Color(hex: "012A4F")
}
