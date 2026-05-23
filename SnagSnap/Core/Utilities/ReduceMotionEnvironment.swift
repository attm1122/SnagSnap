import SwiftUI

/// Environment key for checking and respecting reduce motion settings.
private struct ReduceMotionKey: EnvironmentKey {
    static let defaultValue: Bool = UIAccessibility.isReduceMotionEnabled
}

extension EnvironmentValues {
    var isReduceMotionEnabled: Bool {
        get { self[ReduceMotionKey.self] }
        set { self[ReduceMotionKey.self] = newValue }
    }
}

// MARK: - Conditional Animation View Modifier

extension View {
    /// Applies the given animation only when reduce motion is NOT enabled.
    @ViewBuilder
    func conditionalAnimation(_ animation: Animation) -> some View {
        if UIAccessibility.isReduceMotionEnabled {
            self
        } else {
            self.animation(animation, value: true)
        }
    }
}
