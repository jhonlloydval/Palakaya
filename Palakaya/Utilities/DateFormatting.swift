import Foundation

extension Date {
    /// "6:45 AM"
    var pkTimeLabel: String {
        formatted(.dateTime.hour().minute())
    }

    /// "Today", "Yesterday", or "Nov 3"
    var pkDayLabel: String {
        let cal = Calendar.current
        if cal.isDateInToday(self) { return "Today" }
        if cal.isDateInYesterday(self) { return "Yesterday" }
        return formatted(.dateTime.month(.abbreviated).day())
    }
}
