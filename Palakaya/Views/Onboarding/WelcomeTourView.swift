import SwiftUI

private struct TourTip {
    var icon: String
    var title: String
    var detail: String
}

/// A short, skippable tour shown once right after a new account is created.
struct WelcomeTourView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var step = 0

    private var tips: [TourTip] {
        if appState.isBuyer {
            return [
                TourTip(icon: "storefront.fill", title: "Browse fresh catch",
                        detail: "Market lists catch from fishers near you, with the fair price for each species."),
                TourTip(icon: "hand.raised.fill", title: "Make an offer",
                        detail: "Open a listing and offer a price per kilo. The fisher accepts or declines."),
                TourTip(icon: "creditcard.fill", title: "Pay when accepted",
                        detail: "Accepted offers appear in My Offers. Pay there and keep the receipt."),
                TourTip(icon: "checkmark.seal.fill", title: "Get verified",
                        detail: "Add your business permit in Profile to earn the Verified badge fishers trust."),
            ]
        }
        return [
            TourTip(icon: "water.waves", title: "Log every catch",
                    detail: "Tap Log Catch on Home, pick the fish, enter the kilos. It takes under a minute. Your list is in the blue Catch tab."),
            TourTip(icon: "tag.fill", title: "Check the fair price",
                    detail: "Each catch shows this week's fair price range, so you know your floor before you sell."),
            TourTip(icon: "storefront.fill", title: "Sell in Market",
                    detail: "List your catch and verified buyers send offers. Record the sale when you're paid."),
            TourTip(icon: "sparkles", title: "Ask the Advisor",
                    detail: "Ask in Tagalog or English, for example \"Magkano ang galunggong ngayon?\""),
            TourTip(icon: "wifi.slash", title: "Works without signal",
                    detail: "Everything saves on your phone first and uploads when you're back in range."),
        ]
    }

    private var firstName: String {
        appState.currentUserName.split(separator: " ").first.map(String.init) ?? ""
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("\(step + 1) of \(tips.count)")
                    .font(.system(size: 14, weight: .semibold)).foregroundColor(.pkSub)
                Spacer()
                Button("Skip") { dismiss() }
                    .font(.system(size: 15, weight: .semibold)).foregroundColor(.pkDark)
            }
            .padding(.bottom, 28)

            Text(firstName.isEmpty ? "Welcome to Palakaya" : "Welcome, \(firstName)")
                .font(.system(size: 30, weight: .heavy)).foregroundColor(.pkText)
            Text("A few things to know before your first trip.")
                .font(.system(size: 16, weight: .medium)).foregroundColor(.pkSub)
                .padding(.top, 4)

            TabView(selection: $step) {
                ForEach(tips.indices, id: \.self) { i in
                    tipCard(tips[i]).tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(maxHeight: .infinity)

            PrimaryButton(title: step == tips.count - 1 ? "Start using Palakaya" : "Next") {
                if step == tips.count - 1 { dismiss() }
                else { withAnimation { step += 1 } }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 16)
        .background(Color.pkBg.ignoresSafeArea())
        .fontDesign(.rounded)
    }

    private func tipCard(_ tip: TourTip) -> some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(LinearGradient.pkBrand)
                        .frame(width: 72, height: 72)
                    Image(systemName: tip.icon).font(.system(size: 30, weight: .semibold)).foregroundColor(.white)
                }
                Text(tip.title).font(.system(size: 24, weight: .bold)).foregroundColor(.pkText)
                Text(tip.detail).font(.system(size: 17)).foregroundColor(.pkSub).lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.pkSurface)
            .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(Color.pkBorder))
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .padding(.top, 28)
            .padding(.horizontal, 2)
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }
}
