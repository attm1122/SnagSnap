import SwiftUI
import UIKit

// MARK: - Hex Initialization

extension Color {
    /// Initialize a Color from a hex string.
    ///
    /// Supports formats:
    /// - RGB (12-bit): "#F0F" or "F0F"
    /// - ARGB (16-bit): "#FF00" or "FF00"
    /// - RRGGBB (24-bit): "#FF00FF" or "FF00FF"
    /// - AARRGGBB (32-bit): "#FFFF00FF" or "FFFF00FF"
    ///
    /// Returns nil if the string is not a valid hex color.
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        var red: CGFloat = 0.0
        var green: CGFloat = 0.0
        var blue: CGFloat = 0.0
        var alpha: CGFloat = 1.0

        let length = hexSanitized.count

        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        switch length {
        case 3: // RGB (12-bit)
            red = CGFloat((rgb & 0xF00) >> 8) / 15.0
            green = CGFloat((rgb & 0x0F0) >> 4) / 15.0
            blue = CGFloat(rgb & 0x00F) / 15.0

        case 4: // ARGB (16-bit)
            alpha = CGFloat((rgb & 0xF000) >> 12) / 15.0
            red = CGFloat((rgb & 0x0F00) >> 8) / 15.0
            green = CGFloat((rgb & 0x00F0) >> 4) / 15.0
            blue = CGFloat(rgb & 0x000F) / 15.0

        case 6: // RRGGBB (24-bit)
            red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            blue = CGFloat(rgb & 0x0000FF) / 255.0

        case 8: // AARRGGBB (32-bit)
            alpha = CGFloat((rgb & 0xFF000000) >> 24) / 255.0
            red = CGFloat((rgb & 0x00FF0000) >> 16) / 255.0
            green = CGFloat((rgb & 0x0000FF00) >> 8) / 255.0
            blue = CGFloat(rgb & 0x000000FF) / 255.0

        default:
            return nil
        }

        self.init(
            .sRGB,
            red: red,
            green: green,
            blue: blue,
            opacity: alpha
        )
    }

    /// Initialize from a hex integer value.
    init(hex: UInt, alpha: Double = 1.0) {
        let red = Double((hex & 0xFF0000) >> 16) / 255.0
        let green = Double((hex & 0x00FF00) >> 8) / 255.0
        let blue = Double(hex & 0x0000FF) / 255.0
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
}

// MARK: - Color Manipulation

extension Color {
    /// Lighten the color by a percentage (0.0 to 1.0).
    ///
    /// - Parameter percentage: Amount to lighten, from 0.0 (no change) to 1.0 (white).
    /// - Returns: A lightened version of the color.
    func lightened(by percentage: CGFloat) -> Color {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        guard uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return self
        }

        let clampedPercentage = max(0.0, min(1.0, percentage))

        return Color(
            .sRGB,
            red: Double(min(red + (1.0 - red) * clampedPercentage, 1.0)),
            green: Double(min(green + (1.0 - green) * clampedPercentage, 1.0)),
            blue: Double(min(blue + (1.0 - blue) * clampedPercentage, 1.0)),
            opacity: Double(alpha)
        )
    }

    /// Darken the color by a percentage (0.0 to 1.0).
    ///
    /// - Parameter percentage: Amount to darken, from 0.0 (no change) to 1.0 (black).
    /// - Returns: A darkened version of the color.
    func darkened(by percentage: CGFloat) -> Color {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        guard uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return self
        }

        let clampedPercentage = max(0.0, min(1.0, percentage))
        let factor = 1.0 - clampedPercentage

        return Color(
            .sRGB,
            red: Double(red * factor),
            green: Double(green * factor),
            blue: Double(blue * factor),
            opacity: Double(alpha)
        )
    }

    /// Increase opacity by a percentage.
    ///
    /// - Parameter percentage: Amount to increase opacity, from 0.0 to 1.0.
    func withIncreasedOpacity(by percentage: CGFloat) -> Color {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        guard uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return self
        }

        let newAlpha = min(alpha + percentage, 1.0)
        return Color(.sRGB, red: Double(red), green: Double(green), blue: Double(blue), opacity: Double(newAlpha))
    }

    /// Decrease opacity by a percentage.
    ///
    /// - Parameter percentage: Amount to decrease opacity, from 0.0 to 1.0.
    func withDecreasedOpacity(by percentage: CGFloat) -> Color {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        guard uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return self
        }

        let newAlpha = max(alpha - percentage, 0.0)
        return Color(.sRGB, red: Double(red), green: Double(green), blue: Double(blue), opacity: Double(newAlpha))
    }
}

// MARK: - UIColor Bridge

extension Color {
    /// Convert SwiftUI Color to UIColor.
    var uiColor: UIColor {
        UIColor(self)
    }

    /// Get RGBA components of the color.
    var rgbaComponents: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat)? {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        guard uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return nil
        }

        return (red, green, blue, alpha)
    }

    /// Convert to hex string (RRGGBB format).
    var hexString: String? {
        guard let components = rgbaComponents else { return nil }
        let red = Int(components.red * 255)
        let green = Int(components.green * 255)
        let blue = Int(components.blue * 255)
        return String(format: "#%02X%02X%02X", red, green, blue)
    }

    /// Convert to hex string with alpha (AARRGGBB format).
    var hexStringWithAlpha: String? {
        guard let components = rgbaComponents else { return nil }
        let alpha = Int(components.alpha * 255)
        let red = Int(components.red * 255)
        let green = Int(components.green * 255)
        let blue = Int(components.blue * 255)
        return String(format: "#%02X%02X%02X%02X", alpha, red, green, blue)
    }
}

// MARK: - Status Colors

extension Color {
    /// Get the theme color for a report status.
    static func forReportStatus(_ status: ReportStatus) -> Color {
        switch status {
        case .draft: return Theme.statusDraft
        case .ready: return Theme.statusReady
        case .exported: return Theme.statusExported
        case .archived: return Theme.statusArchived
        }
    }

    /// Get the theme color for an issue status.
    static func forIssueStatus(_ status: IssueStatus) -> Color {
        switch status {
        case .open: return Theme.issueStatusOpen
        case .inProgress: return Theme.issueStatusInProgress
        case .fixed: return Theme.issueStatusResolved
        case .notAnIssue, .archived: return Theme.issueStatusArchived
        }
    }

    /// Get the theme color for an issue severity.
    static func forSeverity(_ severity: IssueSeverity) -> Color {
        switch severity {
        case .low: return Theme.severityLow
        case .medium: return Theme.severityMedium
        case .high: return Theme.severityHigh
        case .urgent: return Theme.severityUrgent
        }
    }
}
