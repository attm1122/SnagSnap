// SnagSnap
// CameraCaptureView.swift
//
// Camera capture wrapper using UIImagePickerController via UIViewControllerRepresentable.

import SwiftUI
import UIKit
import AVFoundation

// MARK: - CameraCaptureViewModel

/// View model managing camera permission state and capture flow.
@Observable
final class CameraCaptureViewModel {

    // MARK: - Properties

    var isPermissionChecked = false
    var isCameraAuthorized = false
    var showPermissionAlert = false
    var capturedImage: UIImage?
    var showPreview = false

    // MARK: - Permission Handling

    /// Checks and requests camera permission if needed.
    @MainActor
    func checkPermission() async {
        isPermissionChecked = true
        let service = CameraPermissionService.shared

        if service.isCameraAuthorized {
            isCameraAuthorized = true
            return
        }

        let granted = await service.requestCameraPermission()
        isCameraAuthorized = granted
        if !granted {
            showPermissionAlert = true
        }
    }

    /// Opens the Settings app for the user to grant camera permission.
    func openSettings() {
        CameraPermissionService.shared.openSettings()
        showPermissionAlert = false
    }
}

// MARK: - CameraCaptureView

/// Full-screen camera capture view with permission handling, image preview,
/// and retake/use photo flow.
struct CameraCaptureView: View {

    // MARK: - Callbacks

    let onCapture: (UIImage) -> Void
    let onCancel: () -> Void

    // MARK: - View Model

    @State private var viewModel = CameraCaptureViewModel()

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                if !viewModel.isPermissionChecked {
                    loadingView
                } else if !viewModel.isCameraAuthorized {
                    permissionDeniedView
                } else if let capturedImage = viewModel.capturedImage, viewModel.showPreview {
                    capturePreviewView(image: capturedImage)
                } else {
                    cameraPickerView
                }
            }
            .alert("Camera Access Required", isPresented: $viewModel.showPermissionAlert) {
                Button("Open Settings") {
                    viewModel.openSettings()
                }
                Button("Cancel", role: .cancel) {
                    onCancel()
                }
            } message: {
                Text("Please allow camera access in Settings to take photos for your inspection issues.")
            }
        }
        .task {
            await viewModel.checkPermission()
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: Theme.spacingM) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Checking camera access...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black)
    }

    // MARK: - Permission Denied View

    private var permissionDeniedView: some View {
        VStack(spacing: Theme.spacingL) {
            Spacer()

            Image(systemName: "camera.fill")
                .font(.system(size: 64, weight: .light))
                .foregroundStyle(.secondary.opacity(0.5))

            Text("Camera Access Required")
                .font(.title2.weight(.semibold))

            Text("SnagSnap needs access to your camera to take photos of inspection issues.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.spacingXL)

            VStack(spacing: Theme.spacingM) {
                SSButton(
                    "Open Settings",
                    style: .primary,
                    icon: "gear",
                    isFullWidth: true
                ) {
                    HapticService.shared.play(.medium)
                    viewModel.openSettings()
                }
                .accessibilityLabel("Open system settings")

                SSButton(
                    "Cancel",
                    style: .secondary,
                    isFullWidth: true
                ) {
                    HapticService.shared.play(.light)
                    onCancel()
                }
                .accessibilityLabel("Cancel")
            }
            .padding(.horizontal, Theme.spacingXL)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Camera Picker View

    private var cameraPickerView: some View {
        ImagePickerControllerRepresentable(sourceType: .camera) { image in
            viewModel.capturedImage = image
            viewModel.showPreview = true
        }
        .ignoresSafeArea()
        .overlay(alignment: .topLeading) {
            Button {
                HapticService.shared.play(.light)
                onCancel()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.white)
                    .shadow(radius: 2)
                    .padding()
            }
            .accessibilityLabel("Cancel camera")
        }
    }

    // MARK: - Capture Preview View

    private func capturePreviewView(image: UIImage) -> some View {
        VStack(spacing: 0) {
            // Image preview
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)

            // Bottom action bar
            VStack(spacing: Theme.spacingS) {
                HStack(spacing: Theme.spacingXL) {
                    // Retake button
                    Button {
                        HapticService.shared.play(.medium)
                        withAnimation {
                            viewModel.capturedImage = nil
                            viewModel.showPreview = false
                        }
                    } label: {
                        VStack(spacing: Theme.spacingXS) {
                            Image(systemName: "arrow.counterclockwise.circle.fill")
                                .font(.system(size: 44))
                            Text("Retake")
                                .font(.caption.weight(.medium))
                        }
                        .foregroundStyle(.primary)
                    }
                    .accessibilityLabel("Retake photo")

                    // Use Photo button
                    Button {
                        HapticService.shared.play(.success)
                        onCapture(image)
                    } label: {
                        VStack(spacing: Theme.spacingXS) {
                            ZStack {
                                Circle()
                                    .fill(Theme.success)
                                    .frame(width: 64, height: 64)

                                Image(systemName: "checkmark")
                                    .font(.system(size: 28, weight: .semibold))
                                    .foregroundStyle(.white)
                            }
                            Text("Use Photo")
                                .font(.caption.weight(.medium))
                        }
                        .foregroundStyle(.primary)
                    }
                    .accessibilityLabel("Use captured photo")
                }
                .padding(.vertical, Theme.spacingM)
            }
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

// MARK: - ImagePickerControllerRepresentable

/// A UIViewControllerRepresentable wrapper for UIImagePickerController
/// that handles both camera capture and photo library selection.
struct ImagePickerControllerRepresentable: UIViewControllerRepresentable {

    let sourceType: UIImagePickerController.SourceType
    let onImageCaptured: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        picker.allowsEditing = false

        // For camera, use full screen and show camera controls
        if sourceType == .camera {
            picker.showsCameraControls = true
            picker.cameraCaptureMode = .photo
        }

        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onImageCaptured: onImageCaptured)
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onImageCaptured: (UIImage) -> Void

        init(onImageCaptured: @escaping (UIImage) -> Void) {
            self.onImageCaptured = onImageCaptured
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                // Normalize image orientation
                let normalizedImage = image.normalizedOrientation()
                onImageCaptured(normalizedImage)
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

// MARK: - UIImage Orientation Helper

private extension UIImage {
    /// Returns a new image with normalized orientation (up).
    func normalizedOrientation() -> UIImage {
        if imageOrientation == .up {
            return self
        }

        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return normalizedImage ?? self
    }
}

// MARK: - Preview

#Preview("Camera Capture - Permission Denied") {
    CameraCaptureView { _ in } onCancel: {}
}
