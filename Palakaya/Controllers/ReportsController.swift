import Foundation

struct ReportSummary {
    var monthLabel: String
    var totalKg: Double
    var salesTotal: Int
    var averageAlignment: Int?
    var fishingDays: Int
    var dailyKg: [Double]
    var topSpecies: [(name: String, kg: Double)]
    var isEmpty: Bool { totalKg == 0 }

    /// Plain-text version for sharing by SMS, Messenger or email.
    var shareText: String {
        var lines = [
            "Palakaya catch report – \(monthLabel)",
            "Total catch: \(totalKg.pkTrimmed) kg",
            "Recorded sales: ₱\(salesTotal.formatted())",
            "Average price alignment: \(averageAlignment.map { "\($0)%" } ?? "no sales yet")",
            "Days fished: \(fishingDays)",
        ]
        if !topSpecies.isEmpty {
            lines.append("Top species: " + topSpecies.map { "\($0.name) \($0.kg.pkTrimmed) kg" }.joined(separator: ", "))
        }
        return lines.joined(separator: "\n")
    }
}

/// Builds the "My Reports" numbers from the fisher's own catch records.
enum ReportsController {
    static func summary(for catches: [CatchRecord], now: Date = Date(), calendar: Calendar = .current) -> ReportSummary {
        let month = catches.filter { calendar.isDate($0.dateLogged, equalTo: now, toGranularity: .month) }

        let sold = month.filter { $0.status == .sold }
        let alignments = sold.compactMap(\.alignment)
        let averageAlignment = alignments.isEmpty ? nil : alignments.reduce(0, +) / alignments.count

        let days = Set(month.map { calendar.startOfDay(for: $0.dateLogged) })

        let today = calendar.startOfDay(for: now)
        let dailyKg: [Double] = (0..<7).reversed().map { offset in
            let day = calendar.date(byAdding: .day, value: -offset, to: today) ?? today
            return month.filter { calendar.isDate($0.dateLogged, inSameDayAs: day) }.reduce(0) { $0 + $1.weight }
        }

        let bySpecies = Dictionary(grouping: month, by: \.species)
            .map { (name: $0.key, kg: $0.value.reduce(0) { $0 + $1.weight }) }
            .sorted { $0.kg > $1.kg }

        return ReportSummary(
            monthLabel: now.formatted(.dateTime.month(.wide).year()),
            totalKg: month.reduce(0) { $0 + $1.weight },
            salesTotal: Int(sold.reduce(0) { $0 + ($1.saleAmount ?? 0) }),
            averageAlignment: averageAlignment,
            fishingDays: days.count,
            dailyKg: dailyKg,
            topSpecies: Array(bySpecies.prefix(3))
        )
    }
}
