import SwiftUI
import UIKit
import Foundation

// MARK: - Haptic Feedback

/// Centralized haptic feedback generator.
enum Haptic {
    /// Light impact feedback for subtle interactions
    static func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    /// Medium impact feedback for standard interactions
    static func medium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    /// Heavy impact feedback for strong interactions
    static func heavy() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }

    /// Soft impact feedback (iOS 13+)
    static func soft() {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.impactOccurred()
    }

    /// Rigid impact feedback (iOS 13+)
    static func rigid() {
        let generator = UIImpactFeedbackGenerator(style: .rigid)
        generator.impactOccurred()
    }

    /// Success notification feedback
    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    /// Error notification feedback
    static func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }

    /// Warning notification feedback
    static func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }

    /// Selection changed feedback
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}

// MARK: - App Information

/// App version and build information helpers.
enum AppInfo {
    /// App version string (e.g., "1.2.3")
    static var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }

    /// App build number string (e.g., "45")
    static var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }

    /// Full version string (e.g., "1.2.3 (45)")
    static var fullVersion: String {
        "\(version) (\(buildNumber))"
    }

    /// App display name
    static var displayName: String {
        Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String
            ?? Bundle.main.infoDictionary?["CFBundleName"] as? String
            ?? "SnagSnap"
    }

    /// App bundle identifier
    static var bundleIdentifier: String {
        Bundle.main.bundleIdentifier ?? "com.snagsnap.app"
    }
}

// MARK: - Device Information

/// Device and system information helpers.
enum DeviceInfo {
    /// Current system version (e.g., "17.0")
    static var systemVersion: String {
        UIDevice.current.systemVersion
    }

    /// Device model name (e.g., "iPhone", "iPad")
    static var model: String {
        UIDevice.current.model
    }

    /// Localized device model name
    static var localizedModel: String {
        UIDevice.current.localizedModel
    }

    /// Device name set by user
    static var name: String {
        UIDevice.current.name
    }

    /// Current user interface idiom
    static var userInterfaceIdiom: UIUserInterfaceIdiom {
        UIDevice.current.userInterfaceIdiom
    }

    /// Whether the device is an iPad
    static var isPad: Bool {
        userInterfaceIdiom == .pad
    }

    /// Whether the device is an iPhone
    static var isPhone: Bool {
        userInterfaceIdiom == .phone
    }

    /// Whether the device is in landscape orientation
    static var isLandscape: Bool {
        let orientation = UIDevice.current.orientation
        return orientation.isLandscape
    }

    /// Whether the device supports haptic feedback
    static var supportsHaptics: Bool {
        // All devices running iOS 17+ support haptics
        true
    }

    /// Screen width
    static var screenWidth: CGFloat {
        UIScreen.main.bounds.width
    }

    /// Screen height
    static var screenHeight: CGFloat {
        UIScreen.main.bounds.height
    }

    /// Whether the device has a notch/dynamic island (safe area > 20)
    static var hasNotch: Bool {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows
            .first?.safeAreaInsets.top ?? 0 > 24
    }

    /// Current brightness level (0.0 to 1.0)
    static var screenBrightness: CGFloat {
        UIScreen.main.brightness
    }
}

// MARK: - Debug Helpers

#if DEBUG
/// Debug logging helper that only prints in debug builds.
func debugLog(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    let filename = (file as NSString).lastPathComponent
    print("[\(filename):\(line)] \(function) -> \(message)")
}
#else
func debugLog(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {}
#endif

// MARK: - Threading Helpers

/// Execute a block on the main thread.
func runOnMain(_ block: @escaping () -> Void) {
    if Thread.isMainThread {
        block()
    } else {
        DispatchQueue.main.async {
            block()
        }
    }
}

/// Execute a block on a background queue.
func runOnBackground(qos: DispatchQoS.QoSClass = .userInitiated, _ block: @escaping () -> Void) {
    DispatchQueue.global(qos: qos).async {
        block()
    }
}

// MARK: - Delay Helpers

/// Execute a block after a specified delay.
func delay(_ seconds: Double, execute: @escaping () -> Void) {
    DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: execute)
}

// MARK: - String Helpers

/// Generate a unique file name for images/documents.
func generateUniqueFileName(extension ext: String = "jpg") -> String {
    let timestamp = Int(Date().timeIntervalSince1970)
    let random = Int.random(in: 1000...9999)
    return "snagsnap_\(timestamp)_\(random).\(ext)"
}

/// Format a file size in bytes to human-readable string.
func formatFileSize(_ bytes: Int64) -> String {
    let formatter = ByteCountFormatter()
    formatter.allowedUnits = [.useKB, .useMB]
    formatter.countStyle = .file
    return formatter.string(fromByteCount: bytes)
}

// MARK: - Validation Helpers

/// Validate an email address format.
func isValidEmail(_ email: String) -> Bool {
    let regex = #"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}"#
    return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: email)
}

/// Validate a phone number (basic international format).
func isValidPhone(_ phone: String) -> Bool {
    let digitsOnly = phone.filter { $0.isNumber }
    return digitsOnly.count >= 7 && digitsOnly.count <= 15
}
