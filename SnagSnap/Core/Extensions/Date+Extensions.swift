import Foundation

// MARK: - Formatters

extension Date {
    /// Shared date formatters for reuse.
    private static let mediumFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    private static let shortFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        return formatter
    }()

    private static let mediumWithTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    private static let reportDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter
    }()

    private static let compactDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        return formatter
    }()

    private static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter
    }()

    // MARK: - Formatted Properties

    /// Formatted date string: "May 23, 2026"
    var formattedMedium: String {
        Date.mediumFormatter.string(from: self)
    }

    /// Short formatted date: "23 May 2026"
    var formattedShort: String {
        Date.shortFormatter.string(from: self)
    }

    /// Formatted date with time: "May 23, 2026 at 2:30 PM"
    var formattedMediumWithTime: String {
        Date.mediumWithTimeFormatter.string(from: self)
    }

    /// Relative time string (e.g., "2 hours ago", "in 3 days")
    var relativeFormatted: String {
        Date.relativeFormatter.localizedString(for: self, relativeTo: Date())
    }

    /// Date string for report display: "May 23, 2026"
    var reportDisplayDate: String {
        Date.reportDateFormatter.string(from: self)
    }

    /// Compact date format: "05/23/2026"
    var compactDate: String {
        Date.compactDateFormatter.string(from: self)
    }

    /// ISO 8601 formatted string.
    var iso8601String: String {
        Date.isoFormatter.string(from: self)
    }

    // MARK: - Boolean Checks

    /// Check if the date is today.
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    /// Check if the date was yesterday.
    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }

    /// Check if the date is tomorrow.
    var isTomorrow: Bool {
        Calendar.current.isDateInTomorrow(self)
    }

    /// Check if the date is in the past.
    var isInPast: Bool {
        self < Date()
    }

    /// Check if the date is in the future.
    var isInFuture: Bool {
        self > Date()
    }

    /// Check if the date is within the last 7 days.
    var isWithinLastWeek: Bool {
        guard let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) else {
            return false
        }
        return self > weekAgo
    }

    /// Check if the date falls on a weekend.
    var isWeekend: Bool {
        let weekday = Calendar.current.component(.weekday, from: self)
        return weekday == 1 || weekday == 7
    }

    // MARK: - Component Accessors

    /// The year component.
    var year: Int {
        Calendar.current.component(.year, from: self)
    }

    /// The month component (1-12).
    var month: Int {
        Calendar.current.component(.month, from: self)
    }

    /// The day component (1-31).
    var day: Int {
        Calendar.current.component(.day, from: self)
    }

    /// The hour component (0-23).
    var hour: Int {
        Calendar.current.component(.hour, from: self)
    }

    /// The minute component (0-59).
    var minute: Int {
        Calendar.current.component(.minute, from: self)
    }

    /// Weekday name (e.g., "Monday").
    var weekdayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: self)
    }

    /// Short month name (e.g., "May").
    var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: self)
    }

    /// Short weekday name (e.g., "Mon").
    var shortWeekdayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: self)
    }

    // MARK: - Date Manipulation

    /// Add days to the date.
    func addingDays(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }

    /// Add hours to the date.
    func addingHours(_ hours: Int) -> Date {
        Calendar.current.date(byAdding: .hour, value: hours, to: self) ?? self
    }

    /// Add minutes to the date.
    func addingMinutes(_ minutes: Int) -> Date {
        Calendar.current.date(byAdding: .minute, value: minutes, to: self) ?? self
    }

    /// The start of the day (midnight).
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    /// The end of the day (23:59:59).
    var endOfDay: Date {
        let components = DateComponents(day: 1, second: -1)
        return Calendar.current.date(byAdding: components, to: startOfDay) ?? self
    }

    // MARK: - Interval Calculations

    /// Days between this date and now.
    var daysAgo: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: self, to: Date())
        return components.day ?? 0
    }

    /// Hours between this date and now.
    var hoursAgo: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour], from: self, to: Date())
        return components.hour ?? 0
    }

    /// Minutes between this date and now.
    var minutesAgo: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.minute], from: self, to: Date())
        return components.minute ?? 0
    }

    /// Time interval formatted as a human-readable duration string.
    /// Example: "2h 30m" for 2 hours and 30 minutes ago.
    var timeAgoAbbreviated: String {
        let minutes = minutesAgo
        if minutes < 1 {
            return "Just now"
        } else if minutes < 60 {
            return "\(minutes)m ago"
        } else if hoursAgo < 24 {
            let remainingMinutes = minutes % 60
            if remainingMinutes > 0 {
                return "\(hoursAgo)h \(remainingMinutes)m ago"
            }
            return "\(hoursAgo)h ago"
        } else {
            return "\(daysAgo)d ago"
        }
    }

    // MARK: - Parsing

    /// Parse an ISO 8601 date string.
    static func fromISO8601String(_ string: String) -> Date? {
        Date.isoFormatter.date(from: string)
    }
}
