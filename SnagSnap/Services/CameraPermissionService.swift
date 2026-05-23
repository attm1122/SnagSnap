//
//  CameraPermissionService.swift
//  SnagSnap
//
//  Manages camera and photo library permission state and requests.
//

import Foundation
import AVFoundation
import Photos
import SwiftUI

/// Comprehensive errors that can occur during permission operations.
enum CameraPermissionError: Error, LocalizedError {
    case cameraUnavailable
    case permissionDenied
    case permissionRestricted
    case unknownAuthorizationStatus
    case settingsOpenFailed

    var errorDescription: String? {
        switch self {
        case .cameraUnavailable:
            return "The device camera is not available."
        case .permissionDenied:
            return "Camera access was denied. Please enable it in Settings."
        case .permissionRestricted:
            return "Camera access is restricted, possibly due to parental controls."
        case .unknownAuthorizationStatus:
            return "An unknown authorization status was encountered."
        case .settingsOpenFailed:
            return "Unable to open Settings app."
        }
    }
}

/// Service that manages all camera and photo library permissions for the app.
///
/// `CameraPermissionService` provides a centralized way to check, request, and observe
/// camera and photo library authorization status. It uses `@Observable` to allow
/// SwiftUI views to reactively update when permission states change.
///
/// ## Usage
/// ```swift
/// @State private var permissionService = CameraPermissionService.shared
///
/// if !permissionService.isCameraAuthorized {
///     Button("Grant Camera Access") {
///         Task {
///             _ = await permissionService.requestCameraPermission()
///         }
///     }
/// }
/// ```
@Observable
class CameraPermissionService {

    // MARK: - Shared Instance

    /// The shared singleton instance.
    static let shared = CameraPermissionService()

    // MARK: - Properties

    /// The current camera (video) authorization status.
    var cameraAuthorizationStatus: AVAuthorizationStatus = .notDetermined

    /// The current photo library (read/write) authorization status.
    var photoLibraryStatus: PHAuthorizationStatus = .notDetermined

    /// Whether the user has granted full camera access.
    var isCameraAuthorized: Bool { cameraAuthorizationStatus == .authorized }

    /// Whether the user has granted photo library access (full or limited).
    var isPhotoLibraryAuthorized: Bool {
        photoLibraryStatus == .authorized || photoLibraryStatus == .limited
    }

    /// Whether the camera permission has been explicitly denied.
    var isCameraDenied: Bool { cameraAuthorizationStatus == .denied }

    /// Whether the photo library permission has been explicitly denied.
    var isPhotoLibraryDenied: Bool { photoLibraryStatus == .denied }

    /// Whether either permission is in a restricted state (e.g., parental controls).
    var isRestricted: Bool {
        cameraAuthorizationStatus == .restricted || photoLibraryStatus == .restricted
    }

    /// Whether both camera and photo library permissions are authorized.
    var hasFullAccess: Bool { isCameraAuthorized && isPhotoLibraryAuthorized }

    /// A human-readable description of the current camera permission state.
    var cameraStatusDescription: String {
        switch cameraAuthorizationStatus {
        case .notDetermined: return "Not Determined"
        case .restricted: return "Restricted"
        case .denied: return "Denied"
        case .authorized: return "Authorized"
        @unknown default: return "Unknown"
        }
    }

    /// A human-readable description of the current photo library permission state.
    var photoLibraryStatusDescription: String {
        switch photoLibraryStatus {
        case .notDetermined: return "Not Determined"
        case .restricted: return "Restricted"
        case .denied: return "Denied"
        case .authorized: return "Authorized"
        case .limited: return "Limited"
        @unknown default: return "Unknown"
        }
    }

    // MARK: - Initialization

    /// Creates a new `CameraPermissionService` and reads current authorization states.
    init() {
        self.cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        self.photoLibraryStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }

    // MARK: - Public Methods - Permission Requests

    /// Requests camera (video) permission from the user.
    ///
    /// If the status is `.notDetermined`, presents the system permission dialog.
    /// For any other status, returns whether the current authorization is `.authorized`.
    ///
    /// - Returns: `true` if camera access is authorized after the request.
    func requestCameraPermission() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)

        if status == .notDetermined {
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            cameraAuthorizationStatus = granted ? .authorized : .denied
            return granted
        }

        let isAuthorized = status == .authorized
        cameraAuthorizationStatus = status
        return isAuthorized
    }

    /// Requests photo library (read/write) permission from the user.
    ///
    /// If the status is `.notDetermined`, presents the system permission dialog.
    /// Accepts both `.authorized` and `.limited` as valid granted states.
    ///
    /// - Returns: `true` if photo library access is authorized or limited after the request.
    func requestPhotoLibraryPermission() async -> Bool {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)

        if status == .notDetermined {
            let newStatus = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            photoLibraryStatus = newStatus
            return newStatus == .authorized || newStatus == .limited
        }

        let isAuthorized = status == .authorized || status == .limited
        photoLibraryStatus = status
        return isAuthorized
    }

    /// Requests both camera and photo library permissions.
    ///
    /// - Returns: A tuple indicating whether each permission was granted.
    func requestAllPermissions() async -> (camera: Bool, photoLibrary: Bool) {
        let cameraGranted = await requestCameraPermission()
        let libraryGranted = await requestPhotoLibraryPermission()
        return (camera: cameraGranted, photoLibrary: libraryGranted)
    }

    // MARK: - Public Methods - Permission Checks

    /// Refreshes and returns the current permission states.
    ///
    /// Reads the current authorization status from both AVFoundation and Photos
    /// frameworks and updates the published properties.
    ///
    /// - Returns: A tuple of `(cameraAuthorized, photoLibraryAuthorized)`.
    @discardableResult
    func checkPermissions() -> (camera: Bool, photoLibrary: Bool) {
        cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        photoLibraryStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        return (isCameraAuthorized, isPhotoLibraryAuthorized)
    }

    /// Checks whether the app can present a camera UI.
    ///
    /// Returns `true` only if the camera is both available as hardware
    /// and authorized for use by the app.
    ///
    /// - Returns: `true` if the camera can be used.
    func canUseCamera() -> Bool {
        guard AVCaptureDevice.default(for: .video) != nil else {
            return false
        }
        return isCameraAuthorized
    }

    /// Checks whether the app can save photos to the library.
    ///
    /// - Returns: `true` if photos can be saved.
    func canSaveToPhotoLibrary() -> Bool {
        isPhotoLibraryAuthorized
    }

    // MARK: - Public Methods - Settings

    /// Opens the Settings app so the user can manually grant permissions.
    ///
    /// Call this when a permission has been denied and the user taps
    /// a button to open Settings.
    func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        guard UIApplication.shared.canOpenURL(url) else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    /// Opens the Settings app and executes a callback when the user returns.
    ///
    /// - Parameter onReturn: A closure called when the app becomes active again.
    func openSettings(onReturn: @escaping () -> Void) {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        guard UIApplication.shared.canOpenURL(url) else { return }

        // Register a one-time observer for when the app becomes active again
        let token = NotificationObserverToken()
        token.observer = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [token] _ in
            if let observer = token.observer {
                NotificationCenter.default.removeObserver(observer)
                token.observer = nil
            }
            onReturn()
        }

        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    // MARK: - Public Methods - Validation

    /// Validates that camera access is available, throwing an error if not.
    ///
    /// - Throws: `CameraPermissionError.cameraUnavailable` if no camera hardware exists.
    ///           `CameraPermissionError.permissionDenied` if access was denied.
    ///           `CameraPermissionError.permissionRestricted` if access is restricted.
    func validateCameraAccess() throws {
        guard AVCaptureDevice.default(for: .video) != nil else {
            throw CameraPermissionError.cameraUnavailable
        }

        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            return
        case .denied:
            throw CameraPermissionError.permissionDenied
        case .restricted:
            throw CameraPermissionError.permissionRestricted
        case .notDetermined:
            // Not determined is not a failure state; caller should request permission
            return
        @unknown default:
            throw CameraPermissionError.unknownAuthorizationStatus
        }
    }
}

private final class NotificationObserverToken {
    var observer: NSObjectProtocol?
}
