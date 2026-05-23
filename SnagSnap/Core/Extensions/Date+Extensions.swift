import Foundation

// MARK: - Display Formatting

extension Date {
    /// A short date string in the current locale (e.g. `"Jun 15, 2024"`).
    var shortDate: String {
        Formatters.shortDate.string(from: self)
    }

    /// A medium date string in the current locale (e.g. `"June 15, 2024"`).
    var mediumDate: String {
        Formatters.mediumDate.string(from: self)
    }

    /// A long date string in the current locale (e.g. `"June 15, 2024 at 2:30 PM"`).
    var longDateTime: String {
        Formatters.longDateTime.string(from: self)
    }

    /// A relative time description (e.g. `"2 hours ago"`, `"Just now"`).
    var relativeTime: String {
        let now = Date()
        let diff = now.timeIntervalSince(self)

        if diff < 10 {
            return "Just now"
        } else if diff < 60 {
            return "\(Int(diff))s ago"
        } else if diff < 3600 {
            let mins = Int(diff / 60)
            return "\(mins)m ago"
        } else if diff < 86400 {
            let hours = Int(diff / 3600)
            return "\(hours)h ago"
        } else if diff < 604800 {
            let days = Int(diff / 86400)
            return "\(days)d ago"
        } else {
            return shortDate
        }
    }

    /// Time only string (e.g. `"2:30 PM"`).
    var timeOnly: String {
        Formatters.timeOnly.string(from: self)
    }

    /// Date suitable for a report header (e.g. `"Inspection – June 15, 2024"`).
    var reportHeaderDate: String {
        Formatters.reportHeader.string(from: self)
    }

    /// ISO-8601 formatted string for API usage.
    var iso8601: String {
        Formatters.iso8601.string(from: self)
    }
}

// MARK: - Relative Descriptions

extension Date {
    /// Returns a human-friendly description relative to now.
    /// - Returns: `"Today"`, `"Yesterday"`, or the short date string.
    var relativeDay: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(self) {
            return "Today"
        } else if calendar.isDateInYesterday(self) {
            return "Yesterday"
        } else {
            return shortDate
        }
    }

    /// Returns a string combining the relative day and time.
    /// Example: `"Today at 2:30 PM"`
    var relativeDayAndTime: String {
        "\(relativeDay) at \(timeOnly)"
    }
}

// MARK: - Formatters Cache

private enum Formatters {
    static let shortDate: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .none
        return f
    }()

    static let mediumDate: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    static let longDateTime: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .long
        f.timeStyle = .short
        return f
    }()

    static let timeOnly: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .short
        return f
    }()

    static let reportHeader: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMMM d, yyyy"
        return f
    }()

    static let iso8601: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()
}

// MARK: - Parsing

extension Date {
    /// Parses an ISO-8601 date string.
    /// - Parameter isoString: The ISO-8601 formatted string.
    /// - Returns: The parsed `Date`, or `nil` if parsing fails.
    static func fromISO8601(_ isoString: String) -> Date? {
        Formatters.iso8601.date(from: isoString)
    }
}

// MARK: - Preview Helpers

#if DEBUG
extension Date {
    /// Creates a date by adding time intervals to now (for previews).
    /// - Parameter hoursAgo: Hours to subtract from the current date.
    /// - Returns: A date in the past.
    static func hoursAgo(_ hours: Double) -> Date {
        Date().addingTimeInterval(-hours * 3600)
    }

    /// Creates a date by adding days to now (for previews).
    /// - Parameter daysAgo: Days to subtract from the current date.
    /// - Returns: A date in the past.
    static func daysAgo(_ days: Double) -> Date {
        Date().addingTimeInterval(-days * 86400)
    }
}
#endif

// MARK: - SwiftUI Preview

#if canImport(SwiftUI)
import SwiftUI

#Preview("Date Extensions") {
    VStack(alignment: .leading, spacing: Theme.spacingM) {
        let now = Date()
        let twoHoursAgo = Date.hoursAgo(2)
        let yesterday = Date.hoursAgo(26)
        let lastWeek = Date.daysAgo(5)

        DateRow(label: "Short Date", value: now.shortDate)
        DateRow(label: "Medium Date", value: now.mediumDate)
        DateRow(label: "Long Date + Time", value: now.longDateTime)
        DateRow(label: "Time Only", value: now.timeOnly)
        DateRow(label: "Report Header", value: now.reportHeaderDate)
        DateRow(label: "Relative Time (now)", value: now.relativeTime)
        DateRow(label: "Relative Time (2h ago)", value: twoHoursAgo.relativeTime)
        DateRow(label: "Relative Day (yesterday)", value: yesterday.relativeDay)
        DateRow(label: "Relative Day+Time", value: lastWeek.relativeDayAndTime)
    }
    .padding(Theme.spacingL)
    .background(Theme.background)
}

private struct DateRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(Theme.callout)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(Theme.bodyMedium)
                .foregroundStyle(.primary)
        }
    }
}
#endif
