import SwiftUI

// MARK: - SSCard

/// A reusable card container with configurable padding, corner radius, shadow,
/// background color, and an optional border.
struct SSCard<Content: View>: View {
    let padding: CGFloat
    let cornerRadius: CGFloat
    let shadowRadius: CGFloat
    let shadowColor: Color
    let shadowY: CGFloat
    let background: Color
    let borderColor: Color?
    let borderWidth: CGFloat
    @ViewBuilder let content: Content

    // MARK: - Initializer

    /// Creates a new ``SSCard``.
    /// - Parameters:
    ///   - padding: Inset padding inside the card (default `16`).
    ///   - cornerRadius: Corner radius of the card (default `12`).
    ///   - shadowRadius: Blur radius of the drop shadow (default `Theme.shadowRadius`).
    ///   - shadowColor: Color of the drop shadow (default `Theme.shadowColor`).
    ///   - shadowY: Vertical offset of the drop shadow (default `2`).
    ///   - background: Fill color behind the card content (default `Theme.cardBackground`).
    ///   - borderColor: Optional stroke color around the card edge.
    ///   - borderWidth: Width of the optional border stroke (default `1`).
    ///   - content: The view content to display inside the card.
    init(
        padding: CGFloat = Theme.spacingM,
        cornerRadius: CGFloat = Theme.cornerRadiusM,
        shadowRadius: CGFloat = Theme.shadowRadius,
        shadowColor: Color = Theme.shadowColor,
        shadowY: CGFloat = Theme.shadowY,
        background: Color = Theme.cardBackground,
        borderColor: Color? = Theme.separator.opacity(0.55),
        borderWidth: CGFloat = 1,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius
        self.shadowColor = shadowColor
        self.shadowY = shadowY
        self.background = background
        self.borderColor = borderColor
        self.borderWidth = borderWidth
        self.content = content()
    }

    // MARK: - Body

    var body: some View {
        content
            .padding(padding)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(borderColor ?? Color.clear, lineWidth: borderColor != nil ? borderWidth : 0)
            )
            .shadow(
                color: shadowColor,
                radius: shadowRadius,
                x: 0,
                y: shadowY
            )
    }
}

// MARK: - Preview

#Preview("SSCard Variants") {
    ScrollView {
        VStack(spacing: Theme.spacingL) {
            // Default card
            SSCard {
                VStack(alignment: .leading, spacing: Theme.spacingS) {
                    Text("Default Card")
                        .font(Theme.title3)
                    Text("This is a standard card with default styling.")
                        .font(Theme.body)
                        .foregroundStyle(.secondary)
                }
            }

            // Card with border
            SSCard(borderColor: Theme.accent) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Theme.warning)
                    Text("Card with accent border")
                        .font(Theme.bodyMedium)
                    Spacer()
                }
            }

            // Large padded card
            SSCard(padding: Theme.spacingXL, cornerRadius: Theme.cornerRadiusXL) {
                VStack(spacing: Theme.spacingM) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(Theme.success)
                    Text("Large Card")
                        .font(Theme.title2)
                    Text("Extra padding and larger corner radius.")
                        .font(Theme.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
            }

            // Minimal card (no shadow)
            SSCard(
                padding: Theme.spacingS,
                shadowRadius: 0,
                shadowY: 0,
                background: Theme.tertiaryBackground
            ) {
                Text("Compact, flat card")
                    .font(Theme.caption)
            }
        }
        .padding(Theme.spacingM)
    }
    .background(Theme.background)
}
