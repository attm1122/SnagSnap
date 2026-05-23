// SnagSnap
// View+EntryAnimations.swift
//
// Entry animation modifiers for lists, cards, and view transitions.

import SwiftUI

// MARK: - Entry Animations

extension View {
    /// Fade + slide entry animation for list and card items.
    /// - Parameter delay: Delay in seconds before the animation starts.
    func entryAnimation(delay: Double = 0) -> some View {
        self
            .opacity(1)
            .transition(
                .asymmetric(
                    insertion: .opacity
                        .combined(with: .move(edge: .bottom))
                        .animation(.easeOut(duration: 0.4).delay(delay)),
                    removal: .opacity
                        .animation(.easeIn(duration: 0.2))
                )
            )
    }

    /// Scale + fade entry animation for badges, indicators, and empty states.
    /// - Parameter delay: Delay in seconds before the animation starts.
    func scaleEntryAnimation(delay: Double = 0) -> some View {
        self
            .opacity(1)
            .transition(
                .asymmetric(
                    insertion: .scale(scale: 0.8)
                        .combined(with: .opacity)
                        .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(delay)),
                    removal: .opacity
                        .animation(.easeIn(duration: 0.2))
                )
            )
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

// MARK: - View Visibility Entry Animation

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

// MARK: - Number Change Animation

extension View {
    /// Animates changes to numeric text values.
    func animateNumberChanges() -> some View {
        self
            .contentTransition(.numericText(countsDown: false))
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: UUID())
    }
}
