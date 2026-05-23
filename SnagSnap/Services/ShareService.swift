// SnagSnap
// ShareService.swift
//
// Service for sharing PDFs and images via the native iOS share sheet.

import UIKit

/// Centralized service for sharing content via the native iOS share sheet.
@Observable
class ShareService {
    
    static let shared = ShareService()
    
    private init() {}
    
    /// Presents a share sheet for the given items.
    ///
    /// - Parameters:
    ///   - items: The items to share (PDF Data, UIImage, URLs, etc.).
    ///   - subject: Optional email subject for share extensions that support it.
    ///   - sourceView: The source view/rect for iPad popover presentation.
    ///   - completion: Called when the share sheet is dismissed.
    func presentShareSheet(
        for items: [Any],
        subject: String? = nil,
        sourceView: UIView? = nil,
        completion: (() -> Void)? = nil
    ) {
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        
        if let subject = subject {
            activityVC.setValue(subject, forKeyPath: "subject")
        }
        
        // Exclude options not relevant
        activityVC.excludedActivityTypes = [
            .assignToContact,
            .postToFacebook,
            .postToTwitter
        ]
        
        // iPad popover support
        if let sourceView = sourceView, let popover = activityVC.popoverPresentationController {
            popover.sourceView = sourceView
            popover.sourceRect = CGRect(x: sourceView.bounds.midX, y: sourceView.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        activityVC.completionWithItemsHandler = { _, _, _, _ in
            completion?()
        }
        
        // Present from the top-most view controller
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            var topVC = rootVC
            while let presented = topVC.presentedViewController {
                topVC = presented
            }
            topVC.present(activityVC, animated: true)
        }
    }
    
    /// Shares a PDF report with a pre-filled subject.
    ///
    /// - Parameters:
    ///   - pdfData: The raw PDF data.
    ///   - reportTitle: The report title used for the share subject.
    ///   - completion: Called when sharing completes.
    func sharePDF(_ pdfData: Data, reportTitle: String, completion: (() -> Void)? = nil) {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("SnagSnap_\(reportTitle.sanitizedForFilename).pdf")
        try? pdfData.write(to: tempURL, options: .atomic)
        
        presentShareSheet(
            for: [tempURL],
            subject: "Property Inspection Report: \(reportTitle)",
            completion: completion
        )
    }
    
    /// Shares one or more images.
    ///
    /// - Parameters:
    ///   - images: The UIImages to share.
    ///   - caption: Optional caption/description.
    ///   - completion: Called when sharing completes.
    func shareImages(_ images: [UIImage], caption: String? = nil, completion: (() -> Void)? = nil) {
        var items: [Any] = images
        if let caption = caption { items.append(caption) }
        presentShareSheet(for: items, completion: completion)
    }
}

// MARK: - String Helpers

private extension String {
    /// Removes characters unsafe for filesystem names.
    var sanitizedForFilename: String {
        let unsafeChars = CharacterSet(charactersIn: "/\\?%*|\"<>:")
        return components(separatedBy: unsafeChars).joined(separator: "_")
            .trimmingCharacters(in: .whitespaces)
    }
}
