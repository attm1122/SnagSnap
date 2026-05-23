import SwiftUI

// MARK: - PrimaryButtonModifier

/// A view modifier that applies the primary (filled navy) button appearance.
struct PrimaryButtonModifier: ViewModifier {
    var isFullWidth: Bool = false

    func body(content: Content) -> some View {
        content
            .font(Theme.bodyMedium)
            .foregroundStyle(.white)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .frame(height: Theme.buttonHeight)
            .padding(.horizontal, Theme.spacingL)
            .background(Theme.primary)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusM, style: .continuous))
    }
}

extension View {
    /// Applies the primary button modifier.
    /// - Parameter isFullWidth: Whether the button expands to fill available width.
    func primaryButtonStyle(isFullWidth: Bool = false) -> some View {
        modifier(PrimaryButtonModifier(isFullWidth: isFullWidth))
    }
}

// MARK: - CardModifier

/// A view modifier that wraps content in a themed card with shadow, corner
/// radius, and optional border.
struct CardModifier: ViewModifier {
    var padding: CGFloat = Theme.spacingM
    var cornerRadius: CGFloat = Theme.cornerRadiusM
    var background: Color = Theme.cardBackground
    var borderColor: Color? = nil
    var shadowRadius: CGFloat = Theme.shadowRadius
    var shadowY: CGFloat = Theme.shadowY

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(borderColor ?? Color.clear, lineWidth: borderColor != nil ? 1 : 0)
            )
            .shadow(color: Theme.shadowColor, radius: shadowRadius, x: 0, y: shadowY)
    }
}

extension View {
    /// Applies the card modifier with the specified configuration.
    func cardModifier(
        padding: CGFloat = Theme.spacingM,
        cornerRadius: CGFloat = Theme.cornerRadiusM,
        background: Color = Theme.cardBackground,
        borderColor: Color? = nil,
        shadowRadius: CGFloat = Theme.shadowRadius,
        shadowY: CGFloat = Theme.shadowY
    ) -> some View {
        modifier(CardModifier(
            padding: padding,
            cornerRadius: cornerRadius,
            background: background,
            borderColor: borderColor,
            shadowRadius: shadowRadius,
            shadowY: shadowY
        ))
    }
}

// MARK: - SectionHeaderModifier

/// A view modifier that styles a view as a section header with top padding
/// and a bottom separator.
struct SectionHeaderModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(Theme.headline)
            .foregroundStyle(.primary)
            .padding(.top, Theme.spacingL)
            .padding(.bottom, Theme.spacingXS)
    }
}

extension View {
    /// Applies the section header text style.
    func sectionHeaderStyle() -> some View {
        modifier(SectionHeaderModifier())
    }
}

// MARK: - Shake Modifier

/// A view modifier that shakes the view horizontally, useful for indicating
/// a validation error.
struct ShakeModifier: ViewModifier {
    @Binding var trigger: Bool
    @State private var offset: CGFloat = 0

    var intensity: CGFloat = 10
    var duration: Double = 0.5

    func body(content: Content) -> some View {
        content
            .offset(x: offset)
            .onChange(of: trigger) { _, shouldShake in
                guard shouldShake else { return }
                trigger = false

                withAnimation(.easeInOut(duration: duration * 0.15)) {
                    offset = -intensity
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + duration * 0.15) {
                    withAnimation(.easeInOut(duration: duration * 0.7)) {
                        let keyframes = [
                            intensity * 0.8,
                            -intensity * 0.6,
                            intensity * 0.4,
                            -intensity * 0.2,
                            intensity * 0.1,
                            0
                        ]
                        for (index, value) in keyframes.enumerated() {
                            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * duration * 0.12) {
                                withAnimation(.easeInOut(duration: duration * 0.1)) {
                                    offset = value
                                }
                            }
                        }
                    }
                }
            }
    }
}

extension View {
    /// Shakes the view horizontally when `trigger` becomes `true`.
    /// - Parameters:
    ///   - trigger: A boolean binding that initiates the shake when set to `true`.
    ///   - intensity: Horizontal displacement in points (default `10`).
    ///   - duration: Total animation duration in seconds (default `0.5`).
    func shake(trigger: Binding<Bool>, intensity: CGFloat = 10, duration: Double = 0.5) -> some View {
        modifier(ShakeModifier(trigger: trigger, intensity: intensity, duration: duration))
    }
}

// MARK: - DismissKeyboardOnTap

#if canImport(UIKit)
/// A view modifier that dismisses the keyboard when the user taps outside
/// an input field.
struct DismissKeyboardOnTapModifier: ViewModifier {
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

extension View {
    /// Dismisses the keyboard when the user taps on this view.
    func dismissKeyboardOnTap() -> some View {
        modifier(DismissKeyboardOnTapModifier())
    }
}
#endif

// MARK: - Preview

#Preview("ViewModifiers") {
    VStack(spacing: Theme.spacingL) {
        // Primary button modifier
        Text("Primary Button Modifier")
            .primaryButtonStyle(isFullWidth: true)

        // Card modifier
        Text("Card Modifier Content")
            .font(Theme.body)
            .cardModifier(borderColor: Theme.accent)

        // Section header modifier
        Text("Section Header Modifier")
            .sectionHeaderStyle()
            .frame(maxWidth: .infinity, alignment: .leading)

        // Shake modifier preview
        ShakePreview()
    }
    .padding(Theme.spacingM)
    .background(Theme.background)
}

// MARK: - Shake Preview Helper

private struct ShakePreview: View {
    @State private var shake = false

    var body: some View {
        SSButton(
            "Shake Me",
            style: .secondary,
            isFullWidth: true,
            action: { shake = true }
        )
        .shake(trigger: $shake)
    }
}
