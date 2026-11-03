import Foundation

/// Builds the notification list from the fisher's own records and the market, instead of fixed sample text.
enum NotificationsController {
    static func items(catches: [CatchRecord], market: [OtherListing], marketIsSample: Bool,
                      now: Date = Date()) -> [NotificationItem] {
        var items: [(date: Date, item: NotificationItem)] = []

        let pending = catches.filter(\.needsSync).count
        if AppConfig.isCloudEnabled && pending > 0 {
            items.append((now, NotificationItem(id: "sync", kind: "SYNC",
                text: "\(pending) record\(pending == 1 ? "" : "s") waiting to upload. Tap the Wi-Fi button on Home when you have signal.",
                time: "Now")))
        }

        if !marketIsSample {
            let today = market.filter(\.fresh).count
            if today > 0 {
                items.append((now, NotificationItem(id: "market", kind: "MARKET",
                    text: "\(today) new catch\(today == 1 ? "" : "es") for sale from other fishers today.", time: "Today")))
            }
        }

        for c in catches {
            switch c.status {
            case .sold:
                let amount = Int(c.saleAmount ?? 0)
                let buyer = c.buyerName.map { " to \($0)" } ?? ""
                items.append((c.dateLogged, NotificationItem(id: "sold-\(c.id)", kind: "SALE",
                    text: "You sold \(c.weight.pkTrimmed) kg of \(c.species)\(buyer) for ₱\(amount.formatted()).",
                    time: relative(c.dateLogged, now))))
            case .listed:
                let price = Int(c.price ?? 0)
                items.append((c.dateLogged, NotificationItem(id: "listed-\(c.id)", kind: "LISTING",
                    text: "Your \(c.species) (\(c.weight.pkTrimmed) kg) is listed at ₱\(price)/kg.",
                    time: relative(c.dateLogged, now))))
            case .available:
                continue
            }
        }

        for (species, info) in FAIR_DB.sorted(by: { $0.key < $1.key }) {
            guard let count = info.saleCount else { continue }
            items.append((now.addingTimeInterval(-1), NotificationItem(id: "price-\(species)", kind: "PRICE UPDATE",
                text: "\(species) fair price is now ₱\(info.low)–₱\(info.high)/kg, based on \(count) recent sales.",
                time: "Today")))
        }

        return items.sorted { $0.date > $1.date }.prefix(20).map(\.item)
    }

    private static func relative(_ date: Date, _ now: Date) -> String {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .short
        return f.localizedString(for: date, relativeTo: now)
    }
}
