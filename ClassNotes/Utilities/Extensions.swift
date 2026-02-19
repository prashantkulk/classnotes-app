import Foundation

extension Date {
    var displayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM, EEEE"
        return formatter.string(from: self)
    }

    var shortDisplayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        return formatter.string(from: self)
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }

    var relativeDisplay: String {
        if isToday { return "Today" }
        if isYesterday { return "Yesterday" }
        return shortDisplayString
    }

    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}
