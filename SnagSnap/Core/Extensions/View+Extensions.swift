import SwiftUI

// MARK: - Keyboard

#if canImport(UIKit)
extension View {
    /// Dismisses the software keyboard.
    func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}
#endif

// MARK: - Conditional Modifiers

extension View {
    /// Applies a transformation if the given condition evaluates to `true`.
    /// - Parameters:
    ///   - condition: The condition to evaluate.
    ///   - transform: The closure to apply when the condition is `true`.
    /// - Returns: Either the transformed view or the original.
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    /// Applies a transformation if the given optional value is non-`nil`.
    /// - Parameters:
    ///   - value: The optional value.
    ///   - transform: The closure to apply when the value is present.
    /// - Returns: Either the transformed view or the original.
    @ViewBuilder
    func ifLet<T, Transform: View>(_ value: T?, transform: (Self, T) -> Transform) -> some View {
        if let value = value {
            transform(self, value)
        } else {
            self
        }
    }
}

// MARK: - Card Style

extension View {
    /// Wraps the view in a standard card appearance using ``Theme`` values.
    /// - Parameters:
    ///   - padding: Inner padding (default `Theme.spacingM`).
    ///   - cornerRadius: Corner radius (default `Theme.cornerRadiusM`).
    ///   - background: Card fill color (default `Theme.cardBackground`).
    ///   - borderColor: Optional border stroke color.
    /// - Returns: A view wrapped in a themed card.
    func cardStyle(
        padding: CGFloat = Theme.spacingM,
        cornerRadius: CGFloat = Theme.cornerRadiusM,
        background: Color = Theme.cardBackground,
        borderColor: Color? = nil
    ) -> some View {
        self
            .padding(padding)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(borderColor ?? Color.clear, lineWidth: borderColor != nil ? 1 : 0)
            )
            .shadow(color: Theme.shadowColor, radius: Theme.shadowRadius, x: 0, y: Theme.shadowY)
    }
}

// MARK: - Rounded Button Style

extension View {
    /// Applies a rounded-rectangle background suitable for tappable row items.
    /// - Parameters:
    ///   - background: Fill color behind the content.
    ///   - cornerRadius: Corner radius (default `Theme.cornerRadiusM`).
    /// - Returns: A view with a rounded rect background.
    func roundedButtonStyle(
        background: Color = Theme.cardBackground,
        cornerRadius: CGFloat = Theme.cornerRadiusM
    ) -> some View {
        self
            .padding(.vertical, Theme.spacingM)
            .padding(.horizontal, Theme.spacingL)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

// MARK: - Frame Helpers

extension View {
    /// Centers the view horizontally within an infinite-max-width frame.
    func centerHorizontally() -> some View {
        self.frame(maxWidth: .infinity, alignment: .center)
    }

    /// Aligns the view to the leading edge within an infinite-max-width frame.
    func alignLeading() -> some View {
        self.frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Aligns the view to the trailing edge within an infinite-max-width frame.
    func alignTrailing() -> some View {
        self.frame(maxWidth: .infinity, alignment: .trailing)
    }

    /// Constrains the view to the theme's maximum content width and centers it.
    func constrainedWidth() -> some View {
        self.frame(maxWidth: Theme.maxContentWidth)
            .centerHorizontally()
    }
}

// MARK: - Preview

#Preview("View Extensions") {
    VStack(spacing: Theme.spacingL) {
        // Card style
        Text("Card-styled content")
            .font(Theme.bodyMedium)
            .cardStyle()

        // Rounded button style
        HStack {
            Image(systemName: "doc.text")
            Text("Rounded button row")
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .font(Theme.body)
        .roundedButtonStyle()

        // Conditional modifier
        Text("Conditional red text")
            .if(true) { view in
                view.foregroundStyle(Theme.error)
            }

        // Aligned frames
        Text("Leading aligned")
            .font(Theme.caption)
            .alignLeading()
            .background(Theme.tertiaryBackground)

        Text("Centered")
            .font(Theme.caption)
            .centerHorizontally()
            .background(Theme.tertiaryBackground)

        Text("Trailing aligned")
            .font(Theme.caption)
            .alignTrailing()
            .background(Theme.tertiaryBackground)
    }
    .padding(Theme.spacingM)
    .background(Theme.background)
}
