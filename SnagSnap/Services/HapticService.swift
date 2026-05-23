// SnagSnap
// HapticService.swift
//
// Centralized haptic feedback service for consistent tactile responses across the app.

import SwiftUI
import UIKit

// MARK: - Haptic Type

/// Defines the available haptic feedback types.
enum HapticType {
    case light, medium, heavy
    case success, warning, error
    case selection
}

// MARK: - Haptic Service

/// A centralized service for playing haptic feedback throughout the app.
///
/// Uses `UIImpactFeedbackGenerator` for impact-style feedback and
/// `UINotificationFeedbackGenerator` for success/warning/error feedback.
/// Call `prepare()` after each feedback to keep the generator ready for the next use.
@Observable
class HapticService {
    static let shared = HapticService()

    private var lightImpact = UIImpactFeedbackGenerator(style: .light)
    private var mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private var heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private var notification = UINotificationFeedbackGenerator()
    private var selection = UISelectionFeedbackGenerator()

    /// Plays the specified haptic feedback.
    /// - Parameter type: The type of haptic feedback to play.
    func play(_ type: HapticType) {
        switch type {
        case .light:
            lightImpact.impactOccurred()
            lightImpact.prepare()
        case .medium:
            mediumImpact.impactOccurred()
            mediumImpact.prepare()
        case .heavy:
            heavyImpact.impactOccurred()
            heavyImpact.prepare()
        case .success:
            notification.notificationOccurred(.success)
            notification.prepare()
        case .warning:
            notification.notificationOccurred(.warning)
            notification.prepare()
        case .error:
            notification.notificationOccurred(.error)
            notification.prepare()
        case .selection:
            selection.selectionChanged()
            selection.prepare()
        }
    }
}

// MARK: - SwiftUI Sensory Feedback View Modifier

extension View {
    /// Applies a native SwiftUI sensory feedback triggered by a value change.
    @available(iOS 17.0, *)
    func hapticFeedback<T: Equatable>(_ type: HapticType, trigger: T) -> some View {
        self.sensoryFeedback(
            type.sensoryFeedbackType,
            trigger: trigger
        ) { _, _ in true }
    }

    /// Applies a conditional sensory feedback triggered by a value change.
    @available(iOS 17.0, *)
    func hapticFeedback<T: Equatable>(_ type: HapticType, trigger: T, condition: @escaping (T, T) -> Bool) -> some View {
        self.sensoryFeedback(type.sensoryFeedbackType, trigger: trigger) { oldValue, newValue in
            condition(oldValue, newValue)
        }
    }
}

@available(iOS 17.0, *)
private extension HapticType {
    var sensoryFeedbackType: SensoryFeedback {
        switch self {
        case .success: return .success
        case .warning: return .warning
        case .error: return .error
        case .selection: return .selection
        case .light: return .impact(flexibility: .rigid, intensity: 0.3)
        case .medium: return .impact(flexibility: .solid, intensity: 0.5)
        case .heavy: return .impact(weight: .heavy, intensity: 0.8)
        }
    }
}
