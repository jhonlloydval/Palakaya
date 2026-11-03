import Foundation

/// Builds the notification list from the fisher's own records and the market, instead of fixed sample text.
enum NotificationsController {
    static func items(catches: [CatchRecord], market: [OtherListing], marketIsSample: Bool,
                      offers: [Offer] = [], now: Date = Date()) -> [NotificationItem] {
        var items: [(date: Date, item: NotificationItem)] = []

        for o in offers {
            let peso = "₱\(o.pricePerKg.pkTrimmed)/kg"
            let date = o.paidAt ?? o.createdAt
            let text: String?
            let kind: String
            switch (o.iAmBuyer, o.status) {
            case (false, .pending):
                kind = "NEW OFFER"
                text = "\(o.buyerName) offered \(peso) for \(o.quantityKg.pkTrimmed) kg of your \(o.species)."
            case (false, .paid):
                kind = "PAYMENT RECEIVED"
                text = "\(o.buyerName) paid ₱\(o.total.formatted()) via \(o.paymentMethod ?? "the app") for your \(o.species). Ref \(o.paymentRef ?? "—")."
            case (true, .accepted):
                kind = "OFFER ACCEPTED"
                text = "\(o.fisherFirstName) accepted your offer for \(o.species). Pay ₱\(o.total.formatted()) in My Offers."
            case (true, .declined):
                kind = "OFFER DECLINED"
                text = "\(o.fisherFirstName) declined your \(peso) offer for \(o.species)."
            case (true, .paid):
                kind = "PAYMENT SENT"
                text = "You paid ₱\(o.total.formatted()) via \(o.paymentMethod ?? "the app") for \(o.species)."
            default:
                kind = ""
                text = nil
            }
            if let text {
                items.append((date, NotificationItem(id: "offer-\(o.id)-\(o.status.rawValue)", kind: kind,
                                                     text: text, time: relative(date, now),
                                                     tab: o.iAmBuyer ? .offers : .market,
                                                     route: o.iAmBuyer ? nil : .buyerMatches(o.catchID))))
            }
        }

        let pending = catches.filter(\.needsSync).count
        if AppConfig.isCloudEnabled && pending > 0 {
            items.append((now, NotificationItem(id: "sync", kind: "SYNC",
                text: "\(pending) record\(pending == 1 ? "" : "s") waiting to upload. Tap the Wi-Fi button on Home when you have signal.",
                time: "Now", tab: .profile, route: .profileInfo(.connectivity))))
        }

        if !marketIsSample {
            let today = market.filter(\.fresh).count
            if today > 0 {
                items.append((now, NotificationItem(id: "market", kind: "MARKET",
                    text: "\(today) new catch\(today == 1 ? "" : "es") for sale from other fishers today.", time: "Today", tab: .market)))
            }
        }

        for c in catches {
            switch c.status {
            case .sold:
                let amount = Int(c.saleAmount ?? 0)
                let buyer = c.buyerName.map { " to \($0)" } ?? ""
                items.append((c.dateLogged, NotificationItem(id: "sold-\(c.id)", kind: "SALE",
                    text: "You sold \(c.weight.pkTrimmed) kg of \(c.species)\(buyer) for ₱\(amount.formatted()).",
                    time: relative(c.dateLogged, now), tab: .catchTab, route: .catchDetails(c.id))))
            case .listed:
                let price = Int(c.price ?? 0)
                items.append((c.dateLogged, NotificationItem(id: "listed-\(c.id)", kind: "LISTING",
                    text: "Your \(c.species) (\(c.weight.pkTrimmed) kg) is listed at ₱\(price)/kg.",
                    time: relative(c.dateLogged, now), tab: .market, route: .listingDetails(c.id))))
            case .available:
                continue
            }
        }

        for (species, info) in FAIR_DB.sorted(by: { $0.key < $1.key }) {
            guard let count = info.saleCount else { continue }
            items.append((now.addingTimeInterval(-1), NotificationItem(id: "price-\(species)", kind: "PRICE UPDATE",
                text: "\(species) fair price is now ₱\(info.low)–₱\(info.high)/kg, based on \(count) recent sales.",
                time: "Today", tab: .home, route: .priceExplorer)))
        }

        return items.sorted { $0.date > $1.date }.prefix(20).map(\.item)
    }

    private static func relative(_ date: Date, _ now: Date) -> String {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .short
        // Never show a future time ("in 1 hr.") for something already logged.
        return date >= now.addingTimeInterval(-60) ? "Just now" : f.localizedString(for: date, relativeTo: now)
    }
}
