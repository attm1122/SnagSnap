// SnagSnap
// ShareService.swift
//
// Unified sharing service for images, PDFs, and report data.

import UIKit

/// Service for sharing images and documents via the system share sheet.
@Observable
final class ShareService {

    // MARK: - Shared Instance

    static let shared = ShareService()

    // MARK: - Private Init

    private init() {}

    // MARK: - Public Methods

    /// Shares an array of images using the system UIActivityViewController.
    ///
    /// - Parameters:
    ///   - images: The images to share.
    ///   - caption: Optional caption text to include with the share.
    ///   - completion: Closure called when the share sheet is dismissed.
    func shareImages(_ images: [UIImage], caption: String? = nil, completion: (() -> Void)? = nil) {
        var items: [Any] = images
        if let caption = caption, !caption.isEmpty {
            items.insert(caption, at: 0)
        }

        let activityController = UIActivityViewController(activityItems: items, applicationActivities: nil)

        if let completion = completion {
            activityController.completionWithItemsHandler = { _, _, _, _ in
                completion()
            }
        }

        // Present from the topmost view controller
        DispatchQueue.main.async {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootViewController = windowScene.windows.first?.rootViewController else {
                return
            }

            var topController = rootViewController
            while let presented = topController.presentedViewController {
                topController = presented
            }

            // For iPad support
            if let popover = activityController.popoverPresentationController {
                popover.sourceView = topController.view
                popover.sourceRect = CGRect(x: topController.view.bounds.midX, y: topController.view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }

            topController.present(activityController, animated: true)
        }
    }

    /// Shares a single image using the system UIActivityViewController.
    ///
    /// - Parameters:
    ///   - image: The image to share.
    ///   - caption: Optional caption text to include with the share.
    ///   - completion: Closure called when the share sheet is dismissed.
    func shareImage(_ image: UIImage, caption: String? = nil, completion: (() -> Void)? = nil) {
        shareImages([image], caption: caption, completion: completion)
    }

    /// Shares a PDF file using the system UIActivityViewController.
    ///
    /// - Parameters:
    ///   - url: The file URL of the PDF to share.
    ///   - completion: Closure called when the share sheet is dismissed.
    func sharePDF(_ url: URL, completion: (() -> Void)? = nil) {
        let activityController = UIActivityViewController(activityItems: [url], applicationActivities: nil)

        if let completion = completion {
            activityController.completionWithItemsHandler = { _, _, _, _ in
                completion()
            }
        }

        DispatchQueue.main.async {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootViewController = windowScene.windows.first?.rootViewController else {
                return
            }

            var topController = rootViewController
            while let presented = topController.presentedViewController {
                topController = presented
            }

            if let popover = activityController.popoverPresentationController {
                popover.sourceView = topController.view
                popover.sourceRect = CGRect(x: topController.view.bounds.midX, y: topController.view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }

            topController.present(activityController, animated: true)
        }
    }

    /// Shares raw PDF data using the system UIActivityViewController.
    ///
    /// - Parameters:
    ///   - pdfData: The raw PDF data to share.
    ///   - reportTitle: The title of the report, used as the subject.
    ///   - completion: Closure called when the share sheet is dismissed.
    func sharePDF(_ pdfData: Data, reportTitle: String, completion: (() -> Void)? = nil) {
        var items: [Any] = [pdfData]
        if !reportTitle.isEmpty {
            items.insert(reportTitle, at: 0)
        }

        let activityController = UIActivityViewController(activityItems: items, applicationActivities: nil)
        activityController.setValue(reportTitle, forKey: "subject")

        activityController.excludedActivityTypes = [
            .assignToContact,
            .postToFacebook,
            .postToTwitter
        ]

        if let completion = completion {
            activityController.completionWithItemsHandler = { _, _, _, _ in
                completion()
            }
        }

        DispatchQueue.main.async {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootViewController = windowScene.windows.first?.rootViewController else {
                return
            }

            var topController = rootViewController
            while let presented = topController.presentedViewController {
                topController = presented
            }

            if let popover = activityController.popoverPresentationController {
                popover.sourceView = topController.view
                popover.sourceRect = CGRect(x: topController.view.bounds.midX, y: topController.view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }

            topController.present(activityController, animated: true)
        }
    }
}
