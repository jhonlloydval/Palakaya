import SwiftUI

struct OnboardingSlide {
    var headline: String
    var sub: String
}

let onboardingSlides: [OnboardingSlide] = [
    OnboardingSlide(headline: "Know what your catch is worth",
                    sub: "Log each catch at the landing site and see a fair price before anyone names theirs."),
    OnboardingSlide(headline: "Check the sea before you go",
                    sub: "Every morning, see the waves, wind and rain for your town, with a simple go, careful or stay-ashore guide."),
    OnboardingSlide(headline: "Sell straight to buyers near you",
                    sub: "List your catch and get offers from verified stalls, carinderias and cooperatives."),
    OnboardingSlide(headline: "Ask in English or Filipino",
                    sub: "The Advisor answers questions about prices, fishing grounds and selling, using your own records."),
    OnboardingSlide(headline: "Catch smarter, sell fairer",
                    sub: "Your records and this week's local prices show you when and where to sell. It all works even with no signal."),
]

/// First-run story. Each step is a photo of Filipino fishers at sea that fades into the night-sea navy,
/// with one line of real app content (a catch, a buyer, a price trend) and the message on the faded part.
struct OnboardingView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isLast: Bool { appState.obStep == onboardingSlides.count - 1 }

    var body: some View {
        @Bindable var appState = appState

        ZStack {
            Color.pkDeepSea.ignoresSafeArea()
            TabView(selection: $appState.obStep) {
                ForEach(onboardingSlides.indices, id: \.self) { i in
                    OnboardingPage(index: i, isActive: appState.obStep == i, reduceMotion: reduceMotion)
                        .tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                Spacer()
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
                    .foregroundColor(.white)
                    .padding(.horizontal, 14).frame(minHeight: 36)
                    .background(Color.black.opacity(0.25))
                    .clipShape(Capsule())
            }
        }
        .shadow(color: .black.opacity(0.3), radius: 6)
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

    var body: some View {
        let slide = onboardingSlides[index]
        GeometryReader { geo in
            let photoHeight = geo.size.height * 0.78
            ZStack(alignment: .top) {
                Color.pkDeepSea
                photo(width: geo.size.width, visibleHeight: photoHeight, screenHeight: geo.size.height)
                // Darkens the top for the logo, and fades the photo into the sea colour where the text sits.
                LinearGradient(colors: [.black.opacity(0.45), .clear], startPoint: .top, endPoint: .bottom)
                    .frame(height: 170)
                LinearGradient(stops: [
                    .init(color: .clear, location: 0.35),
                    .init(color: Color.pkDeepSea.opacity(0.75), location: 0.7),
                    .init(color: Color.pkDeepSea, location: 1),
                ], startPoint: .top, endPoint: .bottom)
                .frame(height: photoHeight)

                VStack(alignment: .leading, spacing: 0) {
                    Spacer()
                    // The first step is just the photo and the message.
                    Group {
                        switch index {
                        case 0: EmptyView()
                        case 1: SeaHighlight()
                        case 2: BuyerHighlight()
                        case 3: AdvisorHighlight()
                        default: PriceHighlight()
                        }
                    }
                    // The one entrance moment: the highlight rises into place when its step is shown.
                    .offset(y: isActive || reduceMotion ? 0 : 24)
                    .opacity(isActive ? 1 : 0)
                    .animation(reduceMotion ? nil : .spring(response: 0.55, dampingFraction: 0.78).delay(0.1), value: isActive)
                    .padding(.bottom, index == 0 ? 0 : 18)

                    Text(slide.headline)
                        .font(.system(size: 30, weight: .heavy))
                        .foregroundColor(.white)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.bottom, 10)
                    Text(slide.sub)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.85))
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, geo.safeAreaInsets.bottom + 190)
            }
        }
        .ignoresSafeArea()
    }

    /// Where the people are in each photo, as fractions of its width and height.
    private static let focusX: [CGFloat] = [0.5, 0.5, 0.4, 0.5, 0.45]
    private static let focus: [CGFloat] = [0.74, 0.5, 0.45, 0.5, 0.5]

    /// Draws the photo larger than the space it shows and slides it so the fishers sit at about a third of the way down the
    /// screen, above the highlight and the text.
    private func photo(width: CGFloat, visibleHeight: CGFloat, screenHeight: CGFloat) -> some View {
        let name = "OnboardingPhoto\(index + 1)"
        let aspect = UIImage(named: name).map { $0.size.height / $0.size.width } ?? 1
        let drawnHeight = max(visibleHeight * 1.25, width * aspect)
        let drawnWidth = max(width, drawnHeight / aspect)
        let wanted = screenHeight * 0.33 - Self.focus[index] * drawnHeight
        let offset = min(0, max(visibleHeight - drawnHeight, wanted))
        let offsetX = min(0, max(width - drawnWidth, width / 2 - Self.focusX[index] * drawnWidth))
        return Image(name)
            .resizable()
            .frame(width: drawnWidth, height: drawnHeight)
            .offset(x: offsetX, y: offset)
            .frame(width: width, height: visibleHeight, alignment: .topLeading)
            .clipped()
            .accessibilityHidden(true)
    }
}

// MARK: - Step highlights (real app content, on see-through glass so the photo stays visible)

private struct GlassFact<Content: View>: View {
    var icon: String
    @ViewBuilder var content: () -> Content
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(Color.white.opacity(0.18)).frame(width: 40, height: 40)
                Image(systemName: icon).font(.system(size: 17, weight: .semibold)).foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 2) { content() }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
        .background(.ultraThinMaterial.opacity(0.7))
        .environment(\.colorScheme, .dark)
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.white.opacity(0.18)))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

private struct SeaHighlight: View {
    var body: some View {
        GlassFact(icon: "water.waves") {
            HStack(spacing: 6) {
                Text("Sea today").font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                Text("Good to go").font(.system(size: 12, weight: .bold)).foregroundColor(Color(hex: "10272D"))
                    .padding(.horizontal, 8).padding(.vertical, 3).background(Color.white).clipShape(Capsule())
            }
            Text("Waves 0.5 m · wind 12 km/h · rain 20%")
                .font(.system(size: 13.5, weight: .medium)).foregroundColor(.white.opacity(0.85))
        }
    }
}

private struct AdvisorHighlight: View {
    var body: some View {
        GlassFact(icon: "sparkles") {
            Text("“Magkano ang galunggong ngayon?”").font(.system(size: 16, weight: .bold)).foregroundColor(.white)
            Text("₱186–₱195 per kg near you, up 6% this week")
                .font(.system(size: 13.5, weight: .medium)).foregroundColor(.white.opacity(0.85))
        }
    }
}

private struct BuyerHighlight: View {
    var body: some View {
        GlassFact(icon: "storefront.fill") {
            HStack(spacing: 4) {
                Text("Liza's Seafood Stall").font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                Image(systemName: "checkmark.seal.fill").font(.system(size: 13)).foregroundColor(.pkAqua)
            }
            Text("Offers ₱210/kg for your Tulingan · 0.8 km away")
                .font(.system(size: 13.5, weight: .medium)).foregroundColor(.white.opacity(0.85))
        }
    }
}

private struct PriceHighlight: View {
    var body: some View {
        GlassFact(icon: "chart.line.uptrend.xyaxis") {
            Text("Galunggong · ₱192/kg").font(.system(size: 16, weight: .bold)).foregroundColor(.white)
            Text("Up 4.2% this week · best to sell Saturday morning")
                .font(.system(size: 13.5, weight: .medium)).foregroundColor(.white.opacity(0.85))
        }
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

struct Wave: Shape {
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
