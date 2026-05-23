import SwiftUI

extension View {
    /// Animates this view into place with a fade + slide entry.
    /// Respects Reduce Motion settings.
    func entryAnimation(delay: Double = 0, offsetY: CGFloat = 16) -> some View {
        modifier(EntryAnimationModifier(delay: delay, offsetY: offsetY))
    }

    /// Animates this view with a scale + fade entry.
    /// Respects Reduce Motion settings.
    func scaleEntryAnimation(delay: Double = 0) -> some View {
        modifier(ScaleEntryAnimationModifier(delay: delay))
    }
}

// MARK: - Entry Animation Modifier

struct EntryAnimationModifier: ViewModifier {
    let delay: Double
    let offsetY: CGFloat
    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : offsetY)
            .onAppear {
                let duration = reduceMotion ? 0.01 : 0.4
                withAnimation(.easeOut(duration: duration).delay(delay)) {
                    appeared = true
                }
            }
    }
}

// MARK: - Scale Entry Animation Modifier

struct ScaleEntryAnimationModifier: ViewModifier {
    let delay: Double
    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .scaleEffect(appeared ? 1.0 : 0.85)
            .onAppear {
                let duration = reduceMotion ? 0.01 : 0.35
                withAnimation(.spring(response: duration, dampingFraction: 0.7).delay(delay)) {
                    appeared = true
                }
            }
    }
}

// MARK: - Animated Button Style

extension ButtonStyle where Self == AnimatedButtonStyle {
    /// A button style that applies press-scale animation and optional haptic feedback.
    /// - Parameters:
    ///   - scale: Scale factor when pressed (default 0.96).
    ///   - haptic: Optional haptic feedback type on press.
    static func animated(scale: CGFloat = 0.96, haptic: HapticType? = nil) -> AnimatedButtonStyle {
        AnimatedButtonStyle(scale: scale, haptic: haptic)
    }
}

/// A button style that combines scale animation with optional haptic feedback.
struct AnimatedButtonStyle: ButtonStyle {
    let scale: CGFloat
    let haptic: HapticType?

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed, let haptic {
                    HapticService.shared.play(haptic)
                }
            }
    }
}

// MARK: - Animate On Appear

extension View {
    /// Animates the view's appearance with a fade and slide when it first becomes visible.
    /// - Parameters:
    ///   - delay: Delay before animation starts.
    ///   - duration: Duration of the animation.
    func animateOnAppear(delay: Double = 0, duration: Double = 0.5) -> some View {
        modifier(AnimateOnAppearModifier(delay: delay, duration: duration))
    }
}

private struct AnimateOnAppearModifier: ViewModifier {
    let delay: Double
    let duration: Double
    @State private var isVisible = false

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 12)
            .animation(.easeOut(duration: duration).delay(delay), value: isVisible)
            .onAppear {
                isVisible = true
            }
    }
}

// MARK: - Preview

#Preview("Entry Animations") {
    ScrollView {
        VStack(spacing: Theme.spacingM) {
            ForEach(0..<5) { i in
                Text("Row \(i + 1)")
                    .font(Theme.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Theme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusM))
                    .entryAnimation(delay: Double(i) * 0.05)
            }

            Divider().padding(.vertical)

            ForEach(0..<3) { i in
                Text("Scaled Row \(i + 1)")
                    .font(Theme.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Theme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusM))
                    .scaleEntryAnimation(delay: Double(i) * 0.08)
            }
        }
        .padding()
    }
    .background(Theme.background)
}
