import SwiftUI

struct OnboardingSlide {
    var headline: String
    var sub: String
}

let onboardingSlides: [OnboardingSlide] = [
    OnboardingSlide(headline: "Know the value of every catch.", sub: "Log what you catch and compare your selling price with recent local market prices."),
    OnboardingSlide(headline: "Connect directly with buyers.", sub: "List available catch and discover verified buyers near your landing site."),
    OnboardingSlide(headline: "Catch smarter. Sell fairer.", sub: "Use your catch history and local price trends to make better decisions."),
]

struct OnboardingView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var appState = appState
        let slide = onboardingSlides[appState.obStep]

        ZStack {
            LinearGradient.pkBrand.ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer()
                Image("PalakayaAppIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 190, height: 190)
                Spacer()

                VStack(alignment: .leading, spacing: 12) {
                    Text(slide.headline)
                        .font(.system(size: 27, weight: .bold))
                        .foregroundColor(.white)
                    Text(slide.sub)
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.85))
                        .lineSpacing(4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 6) {
                    ForEach(0..<onboardingSlides.count, id: \.self) { i in
                        Capsule()
                            .fill(Color.white.opacity(i == appState.obStep ? 1 : 0.4))
                            .frame(width: i == appState.obStep ? 22 : 7, height: 6)
                    }
                }
                .padding(.vertical, 22)
                .frame(maxWidth: .infinity, alignment: .center)

                VStack(spacing: 6) {
                    if appState.obStep < onboardingSlides.count - 1 {
                        Button {
                            appState.obStep += 1
                        } label: {
                            HStack { Text("Continue").fontWeight(.semibold); Image(systemName: "arrow.right") }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.white)
                                .foregroundColor(.pkDark)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    } else {
                        Button {
                            appState.phase = .register
                        } label: {
                            HStack { Text("Get Started").fontWeight(.semibold); Image(systemName: "arrow.right") }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.white)
                                .foregroundColor(.pkDark)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        Button {
                            appState.phase = .login
                        } label: {
                            Text("I already have an account")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.92))
                                .padding(.vertical, 10)
                        }
                    }
                }
                .padding(.bottom, 36)
            }
            .padding(.horizontal, 24)
            .padding(.top, 56)
        }
    }
}
