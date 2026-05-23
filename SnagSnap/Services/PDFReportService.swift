//
//  PDFReportService.swift
//  SnagSnap
//
//  Professional PDF report generation for inspection reports.
//

import UIKit
import PDFKit

/// Custom errors for PDF report generation.
enum PDFReportError: Error, LocalizedError {
    case noIssuesToExport
    case imageLoadFailed
    case pdfRenderingFailed
    case invalidReportData
    case coverPageRenderFailed
    case summaryPageRenderFailed
    case issuePageRenderFailed

    var errorDescription: String? {
        switch self {
        case .noIssuesToExport:
            return "No issues found in the report to export."
        case .imageLoadFailed:
            return "Failed to load one or more images for the PDF."
        case .pdfRenderingFailed:
            return "PDF rendering engine failed to produce output."
        case .invalidReportData:
            return "The report contains invalid or missing data."
        case .coverPageRenderFailed:
            return "Failed to render the cover page."
        case .summaryPageRenderFailed:
            return "Failed to render the summary page."
        case .issuePageRenderFailed:
            return "Failed to render an issue detail page."
        }
    }
}

/// Configurable settings for PDF export customization.
///
/// Use `PDFExportSettings` to control which sections appear in the exported PDF,
/// whether to include photos, watermarks, and inspector details.
struct PDFExportSettings {
    /// Whether to include a styled cover page. Defaults to `true`.
    var includeCoverPage: Bool = true
    /// Whether to include the summary statistics page. Defaults to `true`.
    var includeSummary: Bool = true
    /// Whether to embed issue photos in the PDF. Defaults to `true`.
    var includePhotos: Bool = true
    /// Whether to show status badges on issue pages. Defaults to `true`.
    var includeIssueStatuses: Bool = true
    /// Whether to include inspector/company details on the cover. Defaults to `true`.
    var includeInspectorDetails: Bool = true
    /// Whether to include timestamps on pages. Defaults to `false`.
    var includeTimestamps: Bool = false
    /// Whether to show the "Created with SnagSnap" watermark. Defaults to `false`.
    /// Typically enabled for free-tier users.
    var includeWatermark: Bool = false
    /// Company name to display on the cover page.
    var companyName: String?
    /// Inspector name to display on the cover page.
    var inspectorName: String?
    /// Company phone number for the cover page.
    var companyPhone: String?
    /// Company email address for the cover page.
    var companyEmail: String?

    /// Default settings with all standard sections enabled.
    static var `default`: PDFExportSettings { PDFExportSettings() }

    /// Settings for free-tier users with watermark enabled.
    static var freeTier: PDFExportSettings {
        var settings = PDFExportSettings()
        settings.includeWatermark = true
        return settings
    }
}

/// Service for generating professional PDF inspection reports.
///
/// `PDFReportService` creates beautifully formatted PDF documents using `UIGraphicsPDFRenderer`.
/// The generated PDF includes a cover page, summary statistics, and detailed issue pages
/// with photos, severity indicators, and status badges.
///
/// ## Output Format
/// - **Page Size**: US Letter (612 x 792 points)
/// - **Margins**: 50 points on all sides
/// - **Fonts**: System fonts at professional sizes
/// - **Colors**: Severity and status badges use semantic colors
@Observable
class PDFReportService {

    // MARK: - Shared Instance

    /// The shared singleton instance.
    static let shared = PDFReportService()

    // MARK: - Properties

    /// The file storage service used to load issue photos.
    private let fileStorage: FileStorageService

    // MARK: - Layout Constants

    private let pageWidth: CGFloat = 612.0
    private let pageHeight: CGFloat = 792.0
    private let margin: CGFloat = 50.0
    private let contentWidth: CGFloat = 512.0 // 612 - 2*50

    // MARK: - Initialization

    /// Creates a new `PDFReportService`.
    ///
    /// - Parameter fileStorage: The `FileStorageService` to use for loading images.
    ///   Defaults to the shared instance.
    init(fileStorage: FileStorageService = .shared) {
        self.fileStorage = fileStorage
    }

    // MARK: - Public Methods

    /// Generates a complete PDF report from an inspection report.
    ///
    /// - Parameters:
    ///   - report: The `InspectionReport` to export as PDF.
    ///   - settings: Export configuration options. Defaults to `.default`.
    /// - Returns: Raw `Data` containing the generated PDF document.
    /// - Throws: `PDFReportError` if generation fails at any stage.
    func generatePDF(for report: InspectionReport, settings: PDFExportSettings = .default) throws -> Data {
        let pageBounds = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let renderer = UIGraphicsPDFRenderer(bounds: pageBounds)

        return renderer.pdfData { context in
            var pageNumber = 0

            // Cover Page
            if settings.includeCoverPage {
                pageNumber += 1
                context.beginPage()
                renderCoverPage(
                    context: context,
                    report: report,
                    settings: settings,
                    bounds: pageBounds,
                    pageNumber: pageNumber
                )
            }

            // Summary Page
            if settings.includeSummary {
                pageNumber += 1
                context.beginPage()
                renderSummaryPage(
                    context: context,
                    report: report,
                    settings: settings,
                    bounds: pageBounds,
                    pageNumber: pageNumber
                )
            }

            // Issue Detail Pages
            let issues = report.issues ?? []
            for (index, issue) in issues.enumerated() {
                pageNumber += 1
                context.beginPage()
                renderIssuePage(
                    context: context,
                    issue: issue,
                    index: index,
                    total: issues.count,
                    settings: settings,
                    bounds: pageBounds,
                    pageNumber: pageNumber
                )
            }
        }
    }

    /// Generates a PDF and immediately saves it to disk.
    ///
    /// - Parameters:
    ///   - report: The `InspectionReport` to export.
    ///   - settings: Export configuration options.
    /// - Returns: The file URL of the saved PDF.
    /// - Throws: `PDFReportError` or `FileStorageError` on failure.
    func generateAndSavePDF(
        for report: InspectionReport,
        settings: PDFExportSettings = .default
    ) throws -> URL {
        let pdfData = try generatePDF(for: report, settings: settings)
        let filename = "report_\(report.id.uuidString).pdf"
        return try fileStorage.savePDF(pdfData, filename: filename)
    }

    /// Previews a generated PDF in a `PDFDocument`.
    ///
    /// - Parameters:
    ///   - report: The `InspectionReport` to preview.
    ///   - settings: Export configuration options.
    /// - Returns: A `PDFDocument` ready for display in a `PDFView`.
    /// - Throws: `PDFReportError` if generation fails.
    func previewPDF(for report: InspectionReport, settings: PDFExportSettings = .default) throws -> PDFDocument {
        let pdfData = try generatePDF(for: report, settings: settings)
        guard let document = PDFDocument(data: pdfData) else {
            throw PDFReportError.pdfRenderingFailed
        }
        return document
    }

    // MARK: - Cover Page Rendering

    /// Renders the professional cover page.
    private func renderCoverPage(
        context: UIGraphicsPDFRendererContext,
        report: InspectionReport,
        settings: PDFExportSettings,
        bounds: CGRect,
        pageNumber: Int
    ) {
        let cgContext = context.cgContext

        // Background gradient band at top
        let gradientRect = CGRect(x: 0, y: 0, width: bounds.width, height: 180)
        let gradientColor = UIColor(red: 0.14, green: 0.47, blue: 0.89, alpha: 1.0)
        cgContext.setFillColor(gradientColor.cgColor)
        cgContext.fill(gradientRect)

        // Decorative accent line
        let accentRect = CGRect(x: 0, y: 180, width: bounds.width, height: 4)
        let accentColor = UIColor(red: 0.95, green: 0.58, blue: 0.13, alpha: 1.0)
        cgContext.setFillColor(accentColor.cgColor)
        cgContext.fill(accentRect)

        // App/Report title
        let titleText = report.title as NSString? ?? "Inspection Report"
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 32),
            .foregroundColor: UIColor.white
        ]
        let titleSize = titleText.size(withAttributes: titleAttributes)
        titleText.draw(
            at: CGPoint(x: margin, y: 60),
            withAttributes: titleAttributes
        )

        // Report type badge
        let reportType = report.reportType?.rawValue ?? "Inspection"
        let typeBadgeRect = CGRect(x: margin, y: 110, width: 140, height: 28)
        cgContext.setFillColor(accentColor.cgColor)
        cgContext.fillRoundedRect(typeBadgeRect, cornerRadius: 14)

        let typeAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 13, weight: .semibold),
            .foregroundColor: UIColor.white
        ]
        let typeText = reportType as NSString
        let typeSize = typeText.size(withAttributes: typeAttributes)
        let typeX = typeBadgeRect.midX - typeSize.width / 2
        let typeY = typeBadgeRect.midY - typeSize.height / 2
        typeText.draw(at: CGPoint(x: typeX, y: typeY), withAttributes: typeAttributes)

        // Property Information Section
        var currentY: CGFloat = 230

        let sectionAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .medium),
            .foregroundColor: UIColor.gray
        ]
        let valueAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 15, weight: .regular),
            .foregroundColor: UIColor.darkText
        ]

        // Property name
        "PROPERTY" as NSString.draw(
            at: CGPoint(x: margin, y: currentY),
            withAttributes: sectionAttributes
        )
        currentY += 18
        let propertyName = report.propertyName as NSString? ?? "Unnamed Property"
        propertyName.draw(
            at: CGPoint(x: margin, y: currentY),
            withAttributes: valueAttributes
        )
        currentY += 45

        // Property address
        "ADDRESS" as NSString.draw(
            at: CGPoint(x: margin, y: currentY),
            withAttributes: sectionAttributes
        )
        currentY += 18
        let propertyAddress = report.propertyAddress as NSString? ?? "No address provided"
        propertyAddress.draw(
            at: CGPoint(x: margin, y: currentY),
            withAttributes: valueAttributes
        )
        currentY += 45

        // Inspector details
        if settings.includeInspectorDetails {
            "INSPECTOR" as NSString.draw(
                at: CGPoint(x: margin, y: currentY),
                withAttributes: sectionAttributes
            )
            currentY += 18
            let inspectorName = settings.inspectorName ?? report.inspectorName ?? "Not specified"
            (inspectorName as NSString).draw(
                at: CGPoint(x: margin, y: currentY),
                withAttributes: valueAttributes
            )
            currentY += 45
        }

        // Company details
        if settings.includeInspectorDetails, let companyName = settings.companyName ?? report.companyName, !companyName.isEmpty {
            "COMPANY" as NSString.draw(
                at: CGPoint(x: margin, y: currentY),
                withAttributes: sectionAttributes
            )
            currentY += 18
            (companyName as NSString).draw(
                at: CGPoint(x: margin, y: currentY),
                withAttributes: valueAttributes
            )
            currentY += 45
        }

        // Contact info
        if settings.includeInspectorDetails {
            if let phone = settings.companyPhone, !phone.isEmpty {
                let phoneAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 13),
                    .foregroundColor: UIColor.gray
                ]
                ("📞 \(phone)" as NSString).draw(
                    at: CGPoint(x: margin, y: currentY),
                    withAttributes: phoneAttributes
                )
                currentY += 22
            }
            if let email = settings.companyEmail, !email.isEmpty {
                let emailAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 13),
                    .foregroundColor: UIColor.gray
                ]
                ("✉️ \(email)" as NSString).draw(
                    at: CGPoint(x: margin, y: currentY),
                    withAttributes: emailAttributes
                )
                currentY += 22
            }
        }

        // Date
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .none
        let dateString = dateFormatter.string(from: report.createdAt ?? Date())
        let dateAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.italicSystemFont(ofSize: 13),
            .foregroundColor: UIColor.gray
        ]
        ("Generated on \(dateString)" as NSString).draw(
            at: CGPoint(x: margin, y: bounds.height - 100),
            withAttributes: dateAttributes
        )

        // Page number
        drawPageNumber(context: context, bounds: bounds, pageNumber: pageNumber)

        // Watermark
        if settings.includeWatermark {
            drawWatermark(context: context, bounds: bounds)
        }
    }

    // MARK: - Summary Page Rendering

    /// Renders the summary statistics page.
    private func renderSummaryPage(
        context: UIGraphicsPDFRendererContext,
        report: InspectionReport,
        settings: PDFExportSettings,
        bounds: CGRect,
        pageNumber: Int
    ) {
        let cgContext = context.cgContext
        var currentY: CGFloat = margin

        // Page title
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 26),
            .foregroundColor: UIColor.darkText
        ]
        ("Summary" as NSString).draw(
            at: CGPoint(x: margin, y: currentY),
            withAttributes: titleAttributes
        )
        currentY += 45

        // Horizontal divider
        drawHorizontalLine(context: cgContext, y: currentY, bounds: bounds)
        currentY += 20

        // Issue counts by severity
        let issues = report.issues ?? []
        let title = report.title ?? "Inspection Report"

        // Report overview box
        let overviewRect = CGRect(x: margin, y: currentY, width: contentWidth, height: 70)
        cgContext.setFillColor(UIColor(white: 0.96, alpha: 1.0).cgColor)
        cgContext.fillRoundedRect(overviewRect, cornerRadius: 8)

        let overviewLabelAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .medium),
            .foregroundColor: UIColor.gray
        ]
        let overviewValueAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 22, weight: .bold),
            .foregroundColor: UIColor.darkText
        ]

        // Total issues
        "TOTAL ISSUES" as NSString.draw(
            at: CGPoint(x: margin + 15, y: currentY + 12),
            withAttributes: overviewLabelAttributes
        )
        ("\(issues.count)" as NSString).draw(
            at: CGPoint(x: margin + 15, y: currentY + 32),
            withAttributes: overviewValueAttributes
        )

        // Areas inspected
        let areas = report.areas ?? []
        "AREAS INSPECTED" as NSString.draw(
            at: CGPoint(x: margin + 180, y: currentY + 12),
            withAttributes: overviewLabelAttributes
        )
        ("\(areas.count)" as NSString).draw(
            at: CGPoint(x: margin + 180, y: currentY + 32),
            withAttributes: overviewValueAttributes
        )

        // Report status
        "STATUS" as NSString.draw(
            at: CGPoint(x: margin + 360, y: currentY + 12),
            withAttributes: overviewLabelAttributes
        )
        let statusText = report.status?.rawValue ?? "Draft"
        (statusText as NSString).draw(
            at: CGPoint(x: margin + 360, y: currentY + 32),
            withAttributes: overviewValueAttributes
        )

        currentY += 95

        // Severity breakdown section header
        let sectionAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16, weight: .semibold),
            .foregroundColor: UIColor.darkText
        ]
        ("Issue Breakdown by Severity" as NSString).draw(
            at: CGPoint(x: margin, y: currentY),
            withAttributes: sectionAttributes
        )
        currentY += 30

        // Count issues by severity
        var severityCounts: [String: Int] = [:]
        for issue in issues {
            let severityKey = issue.severity?.rawValue ?? "Unknown"
            severityCounts[severityKey, default: 0] += 1
        }

        // Sort severities by importance
        let severityOrder = ["Critical", "Major", "Minor", "Cosmetic"]
        let sortedSeverities = severityOrder.filter { severityCounts.keys.contains($0) }
            + severityCounts.keys.filter { !severityOrder.contains($0) }.sorted()

        for severity in sortedSeverities {
            guard let count = severityCounts[severity] else { continue }
            let rowRect = CGRect(x: margin, y: currentY, width: contentWidth, height: 36)

            // Alternating row background
            let rowIndex = sortedSeverities.firstIndex(of: severity) ?? 0
            if rowIndex % 2 == 0 {
                cgContext.setFillColor(UIColor(white: 0.98, alpha: 1.0).cgColor)
                cgContext.fill(rowRect)
            }

            // Severity color indicator
            let severityColor = self.severityColor(fromRawValue: severity)
            let indicatorRect = CGRect(x: margin + 10, y: currentY + 10, width: 16, height: 16)
            cgContext.setFillColor(severityColor.cgColor)
            cgContext.fillRoundedRect(indicatorRect, cornerRadius: 4)

            // Severity name
            let nameAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14, weight: .medium),
                .foregroundColor: UIColor.darkText
            ]
            (severity as NSString).draw(
                at: CGPoint(x: margin + 36, y: currentY + 9),
                withAttributes: nameAttributes
            )

            // Count
            let countAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14, weight: .semibold),
                .foregroundColor: UIColor.darkText
            ]
            let countString = "\(count)" as NSString
            let countSize = countString.size(withAttributes: countAttributes)
            countString.draw(
                at: CGPoint(x: bounds.width - margin - countSize.width, y: currentY + 9),
                withAttributes: countAttributes
            )

            currentY += 38
        }

        currentY += 20

        // Area list section
        if !areas.isEmpty {
            drawHorizontalLine(context: cgContext, y: currentY, bounds: bounds)
            currentY += 20

            ("Inspected Areas" as NSString).draw(
                at: CGPoint(x: margin, y: currentY),
                withAttributes: sectionAttributes
            )
            currentY += 30

            let areaLabelAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 13),
                .foregroundColor: UIColor.darkGray
            ]

            for (index, area) in areas.enumerated() {
                let bullet = "•"
                let areaName = area.name ?? "Unnamed Area"
                let areaIssueCount = area.issues?.count ?? 0
                let areaText = "\(bullet) \(areaName) (\(areaIssueCount) issues)" as NSString

                let textRect = CGRect(x: margin + 10, y: currentY, width: contentWidth - 20, height: 22)
                if index % 2 == 0 {
                    cgContext.setFillColor(UIColor(white: 0.98, alpha: 1.0).cgColor)
                    cgContext.fill(textRect)
                }

                areaText.draw(
                    at: CGPoint(x: margin + 10, y: currentY + 3),
                    withAttributes: areaLabelAttributes
                )
                currentY += 24
            }
        }

        // Page number
        drawPageNumber(context: context, bounds: bounds, pageNumber: pageNumber)

        // Watermark
        if settings.includeWatermark {
            drawWatermark(context: context, bounds: bounds)
        }
    }

    // MARK: - Issue Page Rendering

    /// Renders a detailed page for a single issue.
    private func renderIssuePage(
        context: UIGraphicsPDFRendererContext,
        issue: InspectionIssue,
        index: Int,
        total: Int,
        settings: PDFExportSettings,
        bounds: CGRect,
        pageNumber: Int
    ) {
        let cgContext = context.cgContext
        var currentY: CGFloat = margin

        // Issue number badge at top right
        let badgeText = "Issue \(index + 1) of \(total)" as NSString
        let badgeAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .semibold),
            .foregroundColor: UIColor.white
        ]
        let badgeSize = badgeText.size(withAttributes: badgeAttributes)
        let badgeRect = CGRect(
            x: bounds.width - margin - badgeSize.width - 16,
            y: currentY,
            width: badgeSize.width + 16,
            height: 24
        )
        let badgeColor = UIColor(red: 0.14, green: 0.47, blue: 0.89, alpha: 1.0)
        cgContext.setFillColor(badgeColor.cgColor)
        cgContext.fillRoundedRect(badgeRect, cornerRadius: 12)
        badgeText.draw(
            at: CGPoint(
                x: badgeRect.midX - badgeSize.width / 2,
                y: badgeRect.midY - badgeSize.height / 2
            ),
            withAttributes: badgeAttributes
        )

        // Issue title
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 22),
            .foregroundColor: UIColor.darkText
        ]
        let issueTitle = issue.title ?? "Untitled Issue"
        let titleSize = (issueTitle as NSString).size(withAttributes: titleAttributes)
        let maxTitleWidth = contentWidth - badgeRect.width - 20
        let titleRect = CGRect(x: margin, y: currentY, width: maxTitleWidth, height: 30)
        (issueTitle as NSString).draw(in: titleRect, withAttributes: titleAttributes)
        currentY += max(50, titleSize.height + 20)

        // Horizontal divider
        drawHorizontalLine(context: cgContext, y: currentY - 8, bounds: bounds)

        // Area name
        let areaName = issue.area?.name ?? "Unknown Area"
        let areaAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 13),
            .foregroundColor: UIColor.gray
        ]
        ("Area: \(areaName)" as NSString).draw(
            at: CGPoint(x: margin, y: currentY),
            withAttributes: areaAttributes
        )
        currentY += 28

        // Severity and Status badges row
        let badgeY = currentY
        var badgeX = margin

        // Severity badge
        if let severity = issue.severity {
            let severityText = severity.rawValue as NSString
            let severityFont = UIFont.systemFont(ofSize: 12, weight: .semibold)
            let severitySize = severityText.size(withAttributes: [.font: severityFont])
            let severityRect = CGRect(
                x: badgeX,
                y: badgeY,
                width: severitySize.width + 20,
                height: 26
            )
            let severityColor = self.severityColor(severity)
            cgContext.setFillColor(severityColor.cgColor)
            cgContext.fillRoundedRect(severityRect, cornerRadius: 6)

            let severityTextAttributes: [NSAttributedString.Key: Any] = [
                .font: severityFont,
                .foregroundColor: UIColor.white
            ]
            severityText.draw(
                at: CGPoint(
                    x: severityRect.midX - severitySize.width / 2,
                    y: severityRect.midY - severitySize.height / 2
                ),
                withAttributes: severityTextAttributes
            )
            badgeX += severityRect.width + 10
        }

        // Status badge
        if settings.includeIssueStatuses, let status = issue.status {
            let statusText = status.rawValue as NSString
            let statusFont = UIFont.systemFont(ofSize: 12, weight: .semibold)
            let statusSize = statusText.size(withAttributes: [.font: statusFont])
            let statusRect = CGRect(
                x: badgeX,
                y: badgeY,
                width: statusSize.width + 20,
                height: 26
            )
            let statusColor = self.statusColor(status)
            cgContext.setFillColor(statusColor.cgColor)
            cgContext.fillRoundedRect(statusRect, cornerRadius: 6)

            let statusTextAttributes: [NSAttributedString.Key: Any] = [
                .font: statusFont,
                .foregroundColor: UIColor.white
            ]
            statusText.draw(
                at: CGPoint(
                    x: statusRect.midX - statusSize.width / 2,
                    y: statusRect.midY - statusSize.height / 2
                ),
                withAttributes: statusTextAttributes
            )
            badgeX += statusRect.width + 10
        }

        currentY += 42

        // Notes section
        if let notes = issue.notes, !notes.isEmpty {
            let notesLabelAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12, weight: .medium),
                .foregroundColor: UIColor.gray
            ]
            ("NOTES" as NSString).draw(
                at: CGPoint(x: margin, y: currentY),
                withAttributes: notesLabelAttributes
            )
            currentY += 20

            let notesAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 13),
                .foregroundColor: UIColor.darkText
            ]
            let notesRect = CGRect(
                x: margin,
                y: currentY,
                width: contentWidth,
                height: 200
            )
            (notes as NSString).draw(
                in: notesRect,
                withAttributes: notesAttributes
            )

            // Calculate actual text height
            let notesSize = (notes as NSString).boundingRect(
                with: CGSize(width: contentWidth, height: CGFloat.greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: notesAttributes,
                context: nil
            )
            currentY += min(notesSize.height + 10, 210)
        }

        // Photos section
        if settings.includePhotos {
            let photos = issue.photos ?? []
            if !photos.isEmpty {
                currentY += 15
                drawHorizontalLine(context: cgContext, y: currentY, bounds: bounds)
                currentY += 15

                let photosLabelAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 12, weight: .medium),
                    .foregroundColor: UIColor.gray
                ]
                let photoCountText = photos.count == 1 ? "1 Photo" : "\(photos.count) Photos"
                (photoCountText as NSString).draw(
                    at: CGPoint(x: margin, y: currentY),
                    withAttributes: photosLabelAttributes
                )
                currentY += 22

                // Layout photos in a grid
                let photoSize: CGFloat = 130
                let photosPerRow = 3
                let spacing: CGFloat = (contentWidth - CGFloat(photosPerRow) * photoSize) / CGFloat(photosPerRow - 1)

                for (photoIndex, photo) in photos.enumerated() {
                    let row = photoIndex / photosPerRow
                    let col = photoIndex % photosPerRow
                    let photoX = margin + CGFloat(col) * (photoSize + spacing)
                    let photoY = currentY + CGFloat(row) * (photoSize + 10)

                    // Check if we'd exceed page bounds
                    if photoY + photoSize > bounds.height - margin - 30 {
                        // Start a new page for remaining photos
                        drawPageNumber(context: context, bounds: bounds, pageNumber: pageNumber)
                        if settings.includeWatermark {
                            drawWatermark(context: context, bounds: bounds)
                        }

                        context.beginPage()
                        currentY = margin

                        let continuedAttributes: [NSAttributedString.Key: Any] = [
                            .font: UIFont.italicSystemFont(ofSize: 13),
                            .foregroundColor: UIColor.gray
                        ]
                        ("Photos continued..." as NSString).draw(
                            at: CGPoint(x: margin, y: currentY),
                            withAttributes: continuedAttributes
                        )
                        currentY += 30
                    }

                    let photoRect = CGRect(x: photoX, y: photoY, width: photoSize, height: photoSize)

                    // Load and draw the image
                    if let image = fileStorage.loadImage(from: photo.originalImagePath) {
                        // Draw with rounded corners
                        cgContext.saveGState()
                        let path = UIBezierPath(roundedRect: photoRect, cornerRadius: 8)
                        path.addClip()
                        image.draw(in: photoRect)
                        cgContext.restoreGState()

                        // Photo border
                        cgContext.setStrokeColor(UIColor.lightGray.cgColor)
                        cgContext.setLineWidth(0.5)
                        cgContext.strokeRoundedRect(photoRect, cornerRadius: 8)
                    } else {
                        // Placeholder for missing image
                        cgContext.setFillColor(UIColor(white: 0.93, alpha: 1.0).cgColor)
                        cgContext.fillRoundedRect(photoRect, cornerRadius: 8)

                        let placeholderAttributes: [NSAttributedString.Key: Any] = [
                            .font: UIFont.systemFont(ofSize: 11),
                            .foregroundColor: UIColor.gray
                        ]
                        let placeholderText = "Image unavailable" as NSString
                        let phSize = placeholderText.size(withAttributes: placeholderAttributes)
                        placeholderText.draw(
                            at: CGPoint(
                                x: photoRect.midX - phSize.width / 2,
                                y: photoRect.midY - phSize.height / 2
                            ),
                            withAttributes: placeholderAttributes
                        )
                    }

                    // Caption
                    if let caption = photo.caption, !caption.isEmpty {
                        let captionAttributes: [NSAttributedString.Key: Any] = [
                            .font: UIFont.systemFont(ofSize: 9),
                            .foregroundColor: UIColor.gray
                        ]
                        let captionRect = CGRect(
                            x: photoX,
                            y: photoY + photoSize + 2,
                            width: photoSize,
                            height: 14
                        )
                        (caption as NSString).draw(
                            in: captionRect,
                            withAttributes: captionAttributes
                        )
                    }
                }

                let totalRows = (photos.count + photosPerRow - 1) / photosPerRow
                currentY += CGFloat(totalRows) * (photoSize + 25)
            }
        }

        // Page number
        drawPageNumber(context: context, bounds: bounds, pageNumber: pageNumber)

        // Watermark
        if settings.includeWatermark {
            drawWatermark(context: context, bounds: bounds)
        }
    }

    // MARK: - Helper Drawing Methods

    /// Draws a subtle watermark across the page center.
    private func drawWatermark(
        context: UIGraphicsPDFRendererContext,
        bounds: CGRect
    ) {
        let watermarkText = "Created with SnagSnap" as NSString
        let font = UIFont.systemFont(ofSize: 48, weight: .ultraLight)
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 0.25)
        ]

        let textSize = watermarkText.size(withAttributes: textAttributes)
        let centerX = bounds.midX - textSize.width / 2
        let centerY = bounds.midY - textSize.height / 2

        context.cgContext.saveGState()
        context.cgContext.translateBy(x: centerX + textSize.width / 2, y: centerY + textSize.height / 2)
        context.cgContext.rotate(by: -30 * .pi / 180)
        watermarkText.draw(
            at: CGPoint(x: -textSize.width / 2, y: -textSize.height / 2),
            withAttributes: textAttributes
        )
        context.cgContext.restoreGState()
    }

    /// Draws a page number at the bottom center of the page.
    private func drawPageNumber(
        context: UIGraphicsPDFRendererContext,
        bounds: CGRect,
        pageNumber: Int
    ) {
        let pageText = "\(pageNumber)" as NSString
        let pageAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor.lightGray
        ]
        let textSize = pageText.size(withAttributes: pageAttributes)
        pageText.draw(
            at: CGPoint(
                x: bounds.midX - textSize.width / 2,
                y: bounds.height - 30
            ),
            withAttributes: pageAttributes
        )
    }

    /// Draws a horizontal divider line across the content area.
    private func drawHorizontalLine(
        context: CGContext,
        y: CGFloat,
        bounds: CGRect
    ) {
        context.saveGState()
        context.setStrokeColor(UIColor(white: 0.85, alpha: 1.0).cgColor)
        context.setLineWidth(1.0)
        context.move(to: CGPoint(x: margin, y: y))
        context.addLine(to: CGPoint(x: bounds.width - margin, y: y))
        context.strokePath()
        context.restoreGState()
    }

    // MARK: - Color Helpers

    /// Returns the semantic color for an issue severity level.
    ///
    /// - Parameter severity: The `IssueSeverity` to get a color for.
    /// - Returns: A `UIColor` representing the severity.
    private func severityColor(_ severity: IssueSeverity) -> UIColor {
        switch severity {
        case .critical:
            return UIColor(red: 0.85, green: 0.15, blue: 0.15, alpha: 1.0)
        case .major:
            return UIColor(red: 0.95, green: 0.58, blue: 0.13, alpha: 1.0)
        case .minor:
            return UIColor(red: 0.14, green: 0.47, blue: 0.89, alpha: 1.0)
        case .cosmetic:
            return UIColor(red: 0.45, green: 0.45, blue: 0.45, alpha: 1.0)
        }
    }

    /// Returns the semantic color for an issue severity from its raw string value.
    ///
    /// - Parameter rawValue: The raw string value of the severity.
    /// - Returns: A `UIColor` representing the severity.
    private func severityColor(fromRawValue rawValue: String) -> UIColor {
        switch rawValue.lowercased() {
        case "critical":
            return UIColor(red: 0.85, green: 0.15, blue: 0.15, alpha: 1.0)
        case "major":
            return UIColor(red: 0.95, green: 0.58, blue: 0.13, alpha: 1.0)
        case "minor":
            return UIColor(red: 0.14, green: 0.47, blue: 0.89, alpha: 1.0)
        case "cosmetic":
            return UIColor(red: 0.45, green: 0.45, blue: 0.45, alpha: 1.0)
        default:
            return UIColor.gray
        }
    }

    /// Returns the semantic color for an issue status.
    ///
    /// - Parameter status: The `IssueStatus` to get a color for.
    /// - Returns: A `UIColor` representing the status.
    private func statusColor(_ status: IssueStatus) -> UIColor {
        switch status {
        case .open:
            return UIColor(red: 0.85, green: 0.15, blue: 0.15, alpha: 1.0)
        case .inProgress:
            return UIColor(red: 0.95, green: 0.58, blue: 0.13, alpha: 1.0)
        case .resolved:
            return UIColor(red: 0.20, green: 0.65, blue: 0.30, alpha: 1.0)
        case .verified:
            return UIColor(red: 0.14, green: 0.47, blue: 0.89, alpha: 1.0)
        }
    }
}

// MARK: - CGContext Extensions

private extension CGContext {
    /// Fills a rectangle with rounded corners.
    func fillRoundedRect(_ rect: CGRect, cornerRadius: CGFloat) {
        let path = CGPath(
            roundedRect: rect,
            cornerWidth: cornerRadius,
            cornerHeight: cornerRadius,
            transform: nil
        )
        addPath(path)
        fillPath()
    }

    /// Strokes a rectangle with rounded corners.
    func strokeRoundedRect(_ rect: CGRect, cornerRadius: CGFloat) {
        let path = CGPath(
            roundedRect: rect,
            cornerWidth: cornerRadius,
            cornerHeight: cornerRadius,
            transform: nil
        )
        addPath(path)
        strokePath()
    }
}
