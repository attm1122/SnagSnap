// SnagSnap
// HapticService.swift
//
// Centralized haptic feedback service for consistent tactile responses across the app.

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
