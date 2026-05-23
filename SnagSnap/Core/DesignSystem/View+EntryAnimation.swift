// SnagSnap
// View+EntryAnimation.swift
//
// A view modifier that adds a fade + slide entry animation to views.

import SwiftUI

// MARK: - Entry Animation Modifier

/// A view modifier that applies a fade-in and slide-up entry animation.
private struct EntryAnimationModifier: ViewModifier {
    let delay: Double
    @State private var isVisible = false

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 16)
            .onAppear {
                withAnimation(.easeOut(duration: 0.45).delay(delay)) {
                    isVisible = true
                }
            }
    }
}

// MARK: - View Extension

extension View {

    /// Applies a fade + slide entry animation to the view.
    /// - Parameter delay: The delay in seconds before the animation starts (default: 0).
    /// - Returns: A view with the entry animation applied.
    func entryAnimation(delay: Double = 0) -> some View {
        modifier(EntryAnimationModifier(delay: delay))
    }
}

// MARK: - Preview

#Preview("Entry Animation") {
    VStack(spacing: Theme.spacingM) {
        Text("First item")
            .entryAnimation(delay: 0)

        Text("Second item (0.15s delay)")
            .entryAnimation(delay: 0.15)

        Text("Third item (0.3s delay)")
            .entryAnimation(delay: 0.3)
    }
    .padding()
}
