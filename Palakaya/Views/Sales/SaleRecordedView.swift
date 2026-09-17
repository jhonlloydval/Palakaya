import SwiftUI

struct SaleRecordedView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var appState = appState
        if let r = appState.saleResult {
            VStack(spacing: 0) {
                Spacer()
                ZStack {
                    Circle().fill(Color.pkSuccessBg).frame(width: 80, height: 80)
                    Image(systemName: "checkmark").font(.system(size: 30, weight: .black)).foregroundColor(.pkSuccess)
                }
                .padding(.bottom, 20)

                LabelCaps(text: "Sale Recorded").padding(.bottom, 4)
                Text("₱\(r.amount.formatted())").font(.system(size: 34, weight: .bold)).padding(.bottom, 16)

                VStack(spacing: 8) {
                    Text("Price Alignment").font(.system(size: 13)).foregroundColor(.pkSub)
                    Text("\(r.alignment)%").font(.system(size: 22, weight: .bold)).foregroundColor(.pkDark)
                    Text("Your selling price was about \(abs(r.alignment - 100))% \(r.alignment >= 100 ? "above" : "below") the regional benchmark midpoint.")
                        .font(.system(size: 12.5)).foregroundColor(.pkText).multilineTextAlignment(.center).lineSpacing(3)
                }
                .padding(16)
                .frame(maxWidth: .infinity)
                .background(Color.pkSurface2)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .padding(.bottom, 24)

                PrimaryButton(title: "View Home Dashboard") {
                    appState.path = NavigationPath()
                    appState.tab = .home
                }
                Spacer()
            }
            .padding(.horizontal, 32)
            .background(Color.pkBg)
            .navigationBarBackButtonHidden(true)
            .navigationBarHidden(true)
        }
    }
}
