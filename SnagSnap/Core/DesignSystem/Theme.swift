import SwiftUI

/// Central theme configuration for the SnagSnap app.
/// Provides consistent colors, typography, spacing, and layout values.
enum Theme {

    // MARK: - Colors

    /// Deep navy primary color for headers, navigation, and key UI elements.
    static let primary = Color(red: 0.12, green: 0.18, blue: 0.35)

    /// Amber/orange accent for CTAs, badges, and urgent items.
    static let accent = Color(red: 0.95, green: 0.58, blue: 0.13)

    /// Medium blue for secondary interactive elements and links.
    static let secondaryAccent = Color(red: 0.20, green: 0.40, blue: 0.75)

    /// Success green for completed states and positive feedback.
    static let success = Color(red: 0.20, green: 0.78, blue: 0.35)

    /// Warning orange for cautionary states.
    static let warning = Color(red: 1.0, green: 0.65, blue: 0.15)

    /// Error red for failures and destructive actions.
    static let error = Color(red: 0.92, green: 0.26, blue: 0.21)

    /// Info blue for informational highlights and tips.
    static let info = Color(red: 0.18, green: 0.52, blue: 0.96)

    // MARK: - Background Colors

    /// Primary grouped background (adapts to light/dark mode).
    static let background = Color(.systemGroupedBackground)

    /// Card and sheet background.
    static let cardBackground = Color(.secondarySystemGroupedBackground)

    /// Elevated tertiary background for nested content.
    static let tertiaryBackground = Color(.tertiarySystemGroupedBackground)

    // MARK: - Typography

    static let largeTitle = Font.system(.largeTitle, design: .rounded, weight: .bold)
    static let title = Font.system(.title, design: .rounded, weight: .semibold)
    static let title2 = Font.system(.title2, design: .rounded, weight: .semibold)
    static let title3 = Font.system(.title3, design: .rounded, weight: .medium)
    static let headline = Font.system(.headline, design: .default, weight: .semibold)
    static let body = Font.system(.body, design: .default, weight: .regular)
    static let bodyMedium = Font.system(.body, design: .default, weight: .medium)
    static let callout = Font.system(.callout, design: .default, weight: .medium)
    static let caption = Font.system(.caption, design: .default, weight: .medium)
    static let footnote = Font.system(.footnote, design: .default, weight: .regular)

    // MARK: - Spacing

    static let spacingXS: CGFloat = 4
    static let spacingS: CGFloat = 8
    static let spacingM: CGFloat = 16
    static let spacingL: CGFloat = 24
    static let spacingXL: CGFloat = 32
    static let spacingXXL: CGFloat = 48

    // MARK: - Corner Radius

    static let cornerRadiusS: CGFloat = 8
    static let cornerRadiusM: CGFloat = 12
    static let cornerRadiusL: CGFloat = 16
    static let cornerRadiusXL: CGFloat = 20

    // MARK: - Shadows

    static let shadowColor = Color.black.opacity(0.08)
    static let shadowRadius: CGFloat = 8
    static let shadowY: CGFloat = 2

    // MARK: - Layout

    static let maxContentWidth: CGFloat = 680
    static let buttonHeight: CGFloat = 52
    static let iconSizeS: CGFloat = 16
    static let iconSizeM: CGFloat = 20
    static let iconSizeL: CGFloat = 24
    static let iconSizeXL: CGFloat = 32
}
