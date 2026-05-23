import SwiftUI

// MARK: - Tag Variant

/// Defines the visual variant of an ``SSTag``.
enum SSTagVariant {
    case status
    case severity
    case info
    case success
    case warning
    case error
    case accent
}

// MARK: - SSTag

/// A small, pill-shaped tag / badge component for displaying status,
/// severity levels, and semantic labels.
struct SSTag: View {
    let text: String
    let variant: SSTagVariant
    let icon: String?

    // MARK: - Initializer

    /// Creates a new ``SSTag``.
    /// - Parameters:
    ///   - text: The label text displayed inside the tag.
    ///   - variant: Visual style that drives background and foreground colors.
    ///   - icon: Optional SF Symbol name displayed to the left of the text.
    init(_ text: String, variant: SSTagVariant, icon: String? = nil) {
        self.text = text
        self.variant = variant
        self.icon = icon
    }

    init(text: String, style: SSTagVariant, icon: String? = nil) {
        self.init(text, variant: style, icon: icon)
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: Theme.spacingXS) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: Theme.iconSizeS, weight: .medium))
            }
            Text(text)
                .font(Theme.caption)
        }
        .padding(.horizontal, Theme.spacingS + 4)
        .padding(.vertical, Theme.spacingXS + 2)
        .background(backgroundColor.opacity(0.12))
        .foregroundStyle(foregroundColor)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(foregroundColor.opacity(0.18), lineWidth: 0.8)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(text)
    }

    // MARK: - Colors

    private var foregroundColor: Color {
        switch variant {
        case .status:     return Theme.primary
        case .severity:   return Theme.accent
        case .info:       return Theme.info
        case .success:    return Theme.success
        case .warning:    return Theme.warning
        case .error:      return Theme.error
        case .accent:     return Theme.accent
        }
    }

    private var backgroundColor: Color {
        foregroundColor
    }
}

// MARK: - Preview

#Preview("SSTag Variants") {
    VStack(spacing: Theme.spacingM) {
        HStack(spacing: Theme.spacingS) {
            SSTag("Open", variant: .status, icon: "circle")
            SSTag("In Progress", variant: .status, icon: "arrow.triangle.2.circlepath")
            SSTag("Closed", variant: .status, icon: "checkmark.circle")
        }

        HStack(spacing: Theme.spacingS) {
            SSTag("Low", variant: .severity)
            SSTag("Medium", variant: .severity)
            SSTag("High", variant: .severity)
        }

        HStack(spacing: Theme.spacingS) {
            SSTag("Info", variant: .info, icon: "info.circle")
            SSTag("Success", variant: .success, icon: "checkmark")
            SSTag("Warning", variant: .warning, icon: "exclamationmark.triangle")
            SSTag("Error", variant: .error, icon: "xmark.octagon")
        }
    }
    .padding(Theme.spacingL)
    .background(Theme.background)
}
