import SwiftUI

/// Demo checkout for an accepted offer: method → account → one-time code → PIN → confirm → receipt.
/// It looks and validates like a real payment, but no money moves and no provider is contacted.
struct PaymentFlowView: View {
    let offer: Offer
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    private enum Step { case method, account, otp, pin, confirm, processing, done }

    @State private var step: Step = .method
    @State private var method: PaymentMethod = .gcash
    @State private var account = ""
    @State private var otp = ""
    @State private var pin = ""
    @State private var error: String?
    @State private var paidOffer: Offer?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                demoBanner
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        if step != .method && step != .done { channelHeader }
                        content
                        if let error {
                            Text(error).font(.system(size: 13)).foregroundColor(.pkDanger).padding(.top, 10)
                        }
                    }
                    .padding(20)
                }
            }
            .background(Color.pkBg)
            .navigationTitle(step == .done ? "Payment Successful" : "Pay ₱\(offer.total.formatted())")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if step != .processing {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(step == .done ? "Done" : "Cancel") { dismiss() }
                    }
                }
            }
            .interactiveDismissDisabled(step == .processing)
        }
    }

    private var demoBanner: some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill")
            Text("DEMO PAYMENT · no real money is sent")
        }
        .font(.system(size: 12, weight: .bold))
        .foregroundColor(.pkWarning)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.pkWarningBg)
    }

    private var channelHeader: some View {
        HStack(spacing: 12) {
            methodIcon(method)
            VStack(alignment: .leading, spacing: 2) {
                Text(method.name).font(.system(size: 16, weight: .bold))
                Text("Paying \(offer.fisherFirstName) via Palakaya").font(.system(size: 12.5)).foregroundColor(.pkSub)
            }
            Spacer()
            Text("₱\(offer.total.formatted())").font(.system(size: 18, weight: .bold)).foregroundColor(.pkDark)
        }
        .padding(14)
        .background(Color.pkSurface)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.pkBorder))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.bottom, 20)
    }

    @ViewBuilder
    private var content: some View {
        switch step {
        case .method: methodStep
        case .account: accountStep
        case .otp: otpStep
        case .pin: pinStep
        case .confirm: confirmStep
        case .processing: processingStep
        case .done: if let paidOffer { PaymentReceiptContent(offer: paidOffer) }
        }
    }

    private var methodStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            summaryCard
            Text("Choose how to pay").font(.system(size: 15, weight: .semibold)).padding(.top, 8)
            ForEach(PaymentMethod.allCases) { m in
                Button {
                    method = m
                    error = nil
                    step = .account
                } label: {
                    HStack(spacing: 12) {
                        methodIcon(m)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(m.name).font(.system(size: 16, weight: .semibold)).foregroundColor(.pkText)
                            Text(m.subtitle).font(.system(size: 12.5)).foregroundColor(.pkSub)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").foregroundColor(.pkSub)
                    }
                    .padding(14)
                    .frame(minHeight: 60)
                    .background(Color.pkSurface)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.pkBorder))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(offer.species) · \(offer.quantityKg.pkTrimmed) kg × ₱\(offer.pricePerKg.pkTrimmed)")
                .font(.system(size: 14, weight: .semibold))
            Text("Seller: \(offer.fisherFirstName)\(offer.fisherLandingSite.map { ", \($0)" } ?? "")")
                .font(.system(size: 13)).foregroundColor(.pkSub)
            Divider().overlay(Color.pkBorder)
            HStack {
                Text("Total").font(.system(size: 14))
                Spacer()
                Text("₱\(offer.total.formatted())").font(.system(size: 20, weight: .bold)).foregroundColor(.pkDark)
            }
            Text("Service fee ₱0.00").font(.system(size: 12)).foregroundColor(.pkSub)
        }
        .padding(16)
        .background(Color.pkSurface2)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var accountStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            PKTextField(placeholder: method.accountPlaceholder, text: $account, keyboard: .numberPad)
                .pkField(method.accountLabel)
            Text("We'll send a one-time code to confirm it's you.")
                .font(.system(size: 12.5)).foregroundColor(.pkSub).padding(.bottom, 16)
            PrimaryButton(title: "Next") {
                guard DemoPaymentController.isValidAccount(account, for: method) else {
                    error = method.isWallet ? "Enter a valid 11-digit mobile number." : "Enter a valid 10-digit account number."
                    return
                }
                error = nil
                step = .otp
            }
        }
    }

    private var otpStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Enter the 6-digit code sent to \(DemoPaymentController.masked(account, for: method))")
                .font(.system(size: 14)).padding(.bottom, 12)
            PKTextField(placeholder: "000000", text: $otp, keyboard: .numberPad)
                .textContentType(.oneTimeCode)
                .pkField("One-time code")
            InfoBox(text: "Demo code: \(DemoPaymentController.demoOTP)").padding(.bottom, 16)
            PrimaryButton(title: "Verify") {
                guard DemoPaymentController.isValidOTP(otp) else {
                    error = "Incorrect code. Please check and try again."
                    return
                }
                error = nil
                step = .pin
            }
        }
    }

    private var pinStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            PKTextField(placeholder: String(repeating: "•", count: method.pinLength), text: $pin,
                        isSecure: true, keyboard: .numberPad)
                .pkField("Enter your \(method.pinLabel)")
            Text("Demo only: type any \(method.pinLength) digits. Never enter a real PIN.")
                .font(.system(size: 12.5)).foregroundColor(.pkSub).padding(.bottom, 16)
            PrimaryButton(title: "Continue") {
                guard DemoPaymentController.isValidPIN(pin, for: method) else {
                    error = "Enter \(method.pinLength) digits."
                    return
                }
                error = nil
                step = .confirm
            }
        }
    }

    private var confirmStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            summaryCard
            HStack {
                Text("Pay from").foregroundColor(.pkSub)
                Spacer()
                Text("\(method.name) · \(DemoPaymentController.masked(account, for: method))").fontWeight(.semibold)
            }
            .font(.system(size: 14))
            PrimaryButton(title: "Pay ₱\(offer.total.formatted())") { pay() }
                .padding(.top, 8)
        }
    }

    private var processingStep: some View {
        VStack(spacing: 14) {
            ProgressView().scaleEffect(1.4)
            Text("Processing your payment…").font(.system(size: 15, weight: .semibold))
            Text("Please don't close this screen.").font(.system(size: 13)).foregroundColor(.pkSub)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    private func methodIcon(_ m: PaymentMethod) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10).fill(m.color).frame(width: 40, height: 40)
            Image(systemName: m.symbol).font(.system(size: 18, weight: .semibold)).foregroundColor(.white)
        }
        .accessibilityHidden(true)
    }

    private func pay() {
        step = .processing
        let reference = DemoPaymentController.makeReference(for: method)
        Task {
            try? await Task.sleep(for: .seconds(2))
            do {
                try await OfferController.markPaid(offer, method: method.name, reference: reference, appState: appState)
                paidOffer = appState.myOffers.first { $0.id == offer.id }
                step = paidOffer == nil ? .confirm : .done
                if paidOffer == nil { error = "Payment saved, but the receipt could not load. Check My Offers." }
            } catch {
                self.error = error.localizedDescription
                step = .confirm
            }
        }
    }
}
