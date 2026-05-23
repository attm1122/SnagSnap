import SwiftUI

// MARK: - Card Modifier

/// Applies a card-style appearance with background, corner radius, and shadow.
struct CardModifier: ViewModifier {
    var padding: CGFloat
    var backgroundColor: Color
    var cornerRadius: CGFloat
    var shadowRadius: CGFloat

    init(
        padding: CGFloat = Theme.spacingM,
        backgroundColor: Color = Theme.secondaryGroupedBackground,
        cornerRadius: CGFloat = Theme.radiusMedium,
        shadowRadius: CGFloat = Theme.shadowRadiusSmall
    ) {
        self.padding = padding
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius
    }

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(
                color: Theme.shadowColor,
                radius: shadowRadius,
                x: 0,
                y: Theme.shadowYOffsetSmall
            )
    }
}

// MARK: - Primary Button Modifier

/// Filled button style using the app's primary color.
struct PrimaryButtonModifier: ViewModifier {
    var maxWidth: CGFloat?
    var height: CGFloat = 52
    var cornerRadius: CGFloat = Theme.radiusMedium

    func body(content: Content) -> some View {
        content
            .font(Theme.fontHeadline)
            .foregroundStyle(.white)
            .frame(maxWidth: maxWidth ?? .infinity)
            .frame(height: height)
            .background(Theme.primary)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

/// View modifier for primary button appearance
struct PrimaryButtonStyle: ButtonStyle {
    var maxWidth: CGFloat?
    var height: CGFloat = 52
    var cornerRadius: CGFloat = Theme.radiusMedium

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.fontHeadline)
            .foregroundStyle(.white)
            .frame(maxWidth: maxWidth ?? .infinity)
            .frame(height: height)
            .background(
                Theme.primary
                    .opacity(configuration.isPressed ? 0.8 : 1.0)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Secondary Button Modifier

/// Outlined button style with primary color border.
struct SecondaryButtonModifier: ViewModifier {
    var maxWidth: CGFloat?
    var height: CGFloat = 52
    var cornerRadius: CGFloat = Theme.radiusMedium
    var borderWidth: CGFloat = 1.5

    func body(content: Content) -> some View {
        content
            .font(Theme.fontHeadline)
            .foregroundStyle(Theme.primary)
            .frame(maxWidth: maxWidth ?? .infinity)
            .frame(height: height)
            .background(Theme.background)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Theme.primary, lineWidth: borderWidth)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

/// ButtonStyle for secondary (outlined) buttons
struct SecondaryButtonStyle: ButtonStyle {
    var maxWidth: CGFloat?
    var height: CGFloat = 52
    var cornerRadius: CGFloat = Theme.radiusMedium

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.fontHeadline)
            .foregroundStyle(Theme.primary)
            .frame(maxWidth: maxWidth ?? .infinity)
            .frame(height: height)
            .background(
                Theme.background
                    .opacity(configuration.isPressed ? 0.8 : 1.0)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Theme.primary.opacity(configuration.isPressed ? 0.6 : 1.0), lineWidth: 1.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Dismiss Keyboard Modifier

/// Dismisses the keyboard when tapping outside of a text field.
struct DismissKeyboardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onTapGesture {
                UIApplication.shared.sendAction(
                    #selector(UIResponder.resignFirstResponder),
                    to: nil,
                    from: nil,
                    for: nil
                )
            }
    }
}

/// High-performance keyboard dismiss modifier that uses a background gesture
/// without interfering with other tap gestures.
struct HighPerformanceKeyboardDismissModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        dismissKeyboard()
                    }
            )
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}

// MARK: - View Extension Helpers

extension View {
    /// Apply card modifier with default styling
    func card(
        padding: CGFloat = Theme.spacingM,
        backgroundColor: Color = Theme.secondaryGroupedBackground,
        cornerRadius: CGFloat = Theme.radiusMedium,
        shadowRadius: CGFloat = Theme.shadowRadiusSmall
    ) -> some View {
        modifier(CardModifier(
            padding: padding,
            backgroundColor: backgroundColor,
            cornerRadius: cornerRadius,
            shadowRadius: shadowRadius
        ))
    }

    /// Apply primary button appearance
    func primaryButton(
        maxWidth: CGFloat? = .infinity,
        height: CGFloat = 52,
        cornerRadius: CGFloat = Theme.radiusMedium
    ) -> some View {
        modifier(PrimaryButtonModifier(
            maxWidth: maxWidth,
            height: height,
            cornerRadius: cornerRadius
        ))
    }

    /// Apply secondary button appearance
    func secondaryButton(
        maxWidth: CGFloat? = .infinity,
        height: CGFloat = 52,
        cornerRadius: CGFloat = Theme.radiusMedium
    ) -> some View {
        modifier(SecondaryButtonModifier(
            maxWidth: maxWidth,
            height: height,
            cornerRadius: cornerRadius
        ))
    }

    /// Dismiss keyboard on tap outside text fields
    func dismissKeyboardOnTap() -> some View {
        modifier(DismissKeyboardModifier())
    }

    /// High-performance keyboard dismiss that doesn't interfere with other gestures
    func dismissKeyboardOnBackgroundTap() -> some View {
        modifier(HighPerformanceKeyboardDismissModifier())
    }
}
