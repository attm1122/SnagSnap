// SnagSnap
// ReportWorkspaceViewModel.swift
//
// View model managing the report workspace state, issue filtering/sorting,
// PDF generation with staged progress, and export settings.

import SwiftUI
import SwiftData
import PDFKit

// MARK: - Workspace Tab

/// The available tabs in the report workspace.
enum WorkspaceTab: String, CaseIterable, Identifiable {
    case overview = "Overview"
    case areas = "Areas"
    case issues = "Issues"
    case report = "Report"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .overview: return "doc.text.magnifyingglass"
        case .areas: return "square.grid.2x2"
        case .issues: return "exclamationmark.triangle"
        case .report: return "doc.fill"
        }
    }
}

// MARK: - Issue Filter

/// Filter options for the issues list.
enum IssueFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case open = "Open"
    case inProgress = "In Progress"
    case fixed = "Fixed"
    case urgent = "Urgent"
    case high = "High"

    var id: String { rawValue }
}

// MARK: - Issue Sort

/// Sort options for the issues list.
enum IssueSort: String, CaseIterable, Identifiable {
    case newest = "Newest"
    case oldest = "Oldest"
    case severity = "Severity"
    case area = "Area"

    var id: String { rawValue }
}

// MARK: - PDF Generation State

/// Tracks the current state of PDF generation with staged progress.
enum PDFGenerationState: Equatable {
    case idle
    case generating(stage: PDFGenerationStage)
    case success(Data)
    case failed(PDFGenerationError)

    /// Whether the state is currently generating.
    var isGenerating: Bool {
        if case .generating = self { return true }
        return false
    }

    /// The current stage index for the staged loading overlay (0-based).
    var currentStageIndex: Int {
        if case .generating(let stage) = self {
            return stage.rawValue
        }
        return 0
    }

    /// Whether a PDF has been successfully generated and is ready.
    var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }

    /// Whether PDF generation has failed.
    var isFailed: Bool {
        if case .failed = self { return true }
        return false
    }

    static func == (lhs: PDFGenerationState, rhs: PDFGenerationState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle):
            return true
        case (.generating(let a), .generating(let b)):
            return a == b
        case (.success(let a), .success(let b)):
            return a == b
        case (.failed(let a), .failed(let b)):
            return a.localizedDescription == b.localizedDescription
        default:
            return false
        }
    }
}

// MARK: - PDF Generation Stage

/// The individual stages of PDF generation.
enum PDFGenerationStage: Int, CaseIterable {
    case preparing = 0
    case addingPhotos = 1
    case creatingPDF = 2
    case savingFile = 3

    var label: String {
        switch self {
        case .preparing:    return "Preparing report"
        case .addingPhotos: return "Adding photos"
        case .creatingPDF:  return "Creating PDF"
        case .savingFile:   return "Saving file"
        }
    }

    static var allLabels: [String] { allCases.map(\.label) }
}

// MARK: - PDF Generation Error

/// A wrapper error type for PDF generation failures, making it Equatable.
struct PDFGenerationError: Error, LocalizedError {
    let underlying: Error

    var errorDescription: String? {
        underlying.localizedDescription
    }

    static func == (lhs: PDFGenerationError, rhs: PDFGenerationError) -> Bool {
        lhs.localizedDescription == rhs.localizedDescription
    }
}

// MARK: - ReportWorkspaceViewModel

/// View model for the report workspace, managing tab selection, issue filtering,
/// sorting, PDF generation with staged progress, and export settings.
@Observable
final class ReportWorkspaceViewModel {

    // MARK: - Tab & UI State

    /// The currently selected workspace tab.
    var selectedTab: WorkspaceTab = .overview

    /// Whether the edit report sheet is presented.
    var showEditSheet = false

    /// Whether the add area sheet is presented.
    var showAddAreaSheet = false

    /// Whether the add issue sheet is presented.
    var showAddIssueSheet = false

    // MARK: - Issue Filtering & Sorting

    /// The active issue filter.
    var issueFilter: IssueFilter = .all

    /// The active issue sort order.
    var issueSort: IssueSort = .newest

    // MARK: - PDF Generation

    /// Current state of PDF generation.
    var pdfState: PDFGenerationState = .idle

    /// Whether the intelligent share prompt is presented.
    var showSharePrompt = false

    /// Export settings for PDF generation.
    var exportSettings = PDFExportSettings()

    /// Generated PDF data ready for sharing.
    var pdfDataToShare: Data?

    /// The file URL of the most recently saved PDF for this report.
    var latestPDFURL: URL?

    // MARK: - Dependencies

    private let pdfService = PDFReportService.shared

    // MARK: - Computed Properties

    /// Returns issues from the report filtered by the current filter setting.
    func filteredIssues(from report: InspectionReport) -> [InspectionIssue] {
        let allIssues = report.issues ?? []

        switch issueFilter {
        case .all:
            return allIssues
        case .open:
            return allIssues.filter { $0.status == .open }
        case .inProgress:
            return allIssues.filter { $0.status == .inProgress }
        case .fixed:
            return allIssues.filter { $0.status == .fixed }
        case .urgent:
            return allIssues.filter { $0.severity == .urgent }
        case .high:
            return allIssues.filter { $0.severity == .high }
        }
    }

    /// Returns filtered issues sorted by the current sort setting.
    func sortedAndFilteredIssues(from report: InspectionReport) -> [InspectionIssue] {
        let filtered = filteredIssues(from: report)

        switch issueSort {
        case .newest:
            return filtered.sorted { $0.createdAt > $1.createdAt }
        case .oldest:
            return filtered.sorted { $0.createdAt < $1.createdAt }
        case .severity:
            return filtered.sorted { $0.severity.priority > $1.severity.priority }
        case .area:
            return filtered.sorted {
                ($0.area?.name ?? "").localizedCaseInsensitiveCompare($1.area?.name ?? "") == .orderedAscending
            }
        }
    }

    /// Whether a PDF is currently being generated.
    var isGeneratingPDF: Bool {
        pdfState.isGenerating
    }

    /// Whether a PDF has been successfully generated and is ready to share.
    var canSharePDF: Bool {
        pdfState.isSuccess
    }

    // MARK: - PDF Actions

    /// Generates a PDF for the given report using current export settings.
    /// Progresses through animated stages with Task.sleep for visual feedback.
    /// Saves the PDF to disk and updates the report model with the PDF reference.
    @MainActor
    func generatePDF(for report: InspectionReport, modelContext: ModelContext) {
        guard pdfState == .idle || pdfState.isFailed else { return }

        HapticService.shared.play(.medium)

        Task {
            do {
                // Stage 1: Preparing
                pdfState = .generating(stage: .preparing)
                try await Task.sleep(nanoseconds: 400_000_000)

                // Stage 2: Adding photos
                pdfState = .generating(stage: .addingPhotos)
                let settings = buildExportSettings(for: report)
                try await Task.sleep(nanoseconds: 600_000_000)

                // Stage 3: Creating PDF (actual work)
                pdfState = .generating(stage: .creatingPDF)
                let pdfData = try pdfService.generatePDF(for: report, settings: settings)
                try await Task.sleep(nanoseconds: 400_000_000)

                // Stage 4: Saving
                pdfState = .generating(stage: .savingFile)
                let filename = FileStorageService.shared.pdfFilename(for: report.id)
                let pdfURL = try FileStorageService.shared.savePDF(pdfData, filename: filename)
                self.latestPDFURL = pdfURL

                // Update report
                report.latestPDFPath = filename
                report.lastExportedAt = Date()
                report.status = .exported
                try modelContext.save()

                // Success!
                try await Task.sleep(nanoseconds: 300_000_000)
                pdfState = .success(pdfData)
                pdfDataToShare = pdfData
                HapticService.shared.play(.success)

            } catch {
                pdfState = .failed(PDFGenerationError(underlying: error))
                HapticService.shared.play(.error)
            }
        }
    }

    /// Resets the PDF generation state to idle.
    func resetPDFState() {
        pdfState = .idle
        pdfDataToShare = nil
    }

    /// Prepares the share sheet with generated PDF data.
    func prepareShare() {
        if case .success(let data) = pdfState {
            pdfDataToShare = data
            HapticService.shared.play(.light)
        }
    }

    /// Checks if a previously generated PDF exists for the given report.
    func hasExistingPDF(for report: InspectionReport) -> Bool {
        guard let path = report.latestPDFPath else { return false }
        return FileStorageService.shared.pdfExists(named: path)
    }

    /// Loads the existing PDF data for a report, if available.
    func loadExistingPDF(for report: InspectionReport) -> Data? {
        guard let path = report.latestPDFPath else { return nil }
        return FileStorageService.shared.loadPDF(named: path)
    }

    /// Deletes the existing PDF for a report.
    func deleteExistingPDF(for report: InspectionReport, modelContext: ModelContext) {
        guard let path = report.latestPDFPath else { return }
        try? FileStorageService.shared.deletePDF(named: path)
        report.latestPDFPath = nil
        report.lastExportedAt = nil
        try? modelContext.save()
    }

    /// Shares the latest generated PDF for the report using the share service.
    func shareLatestPDF(for report: InspectionReport) {
        guard let path = report.latestPDFPath,
              let pdfData = FileStorageService.shared.loadPDF(named: path) else {
            return
        }
        HapticService.shared.play(.light)
        ShareService.shared.sharePDF(pdfData, reportTitle: report.title)
    }

    /// Shares PDF data directly via the share service.
    func sharePDFData(_ data: Data, reportTitle: String) {
        HapticService.shared.play(.light)
        ShareService.shared.sharePDF(data, reportTitle: reportTitle)
    }

    /// Checks if a report can be shared without regenerating the PDF.
    /// Returns `true` if the report has not been modified since the last PDF export.
    func canShareWithoutRegenerating(report: InspectionReport) -> Bool {
        guard let lastExportedAt = report.lastExportedAt else { return false }
        // Report has been modified more recently than the last PDF export
        return report.updatedAt <= lastExportedAt
    }

    /// Checks for an existing PDF on initialization and restores the state if found.
    func checkForExistingPDF(for report: InspectionReport) {
        guard let path = report.latestPDFPath,
              FileStorageService.shared.pdfExists(named: path),
              let data = FileStorageService.shared.loadPDF(named: path) else {
            return
        }
        pdfState = .success(data)
        pdfDataToShare = data
        latestPDFURL = FileStorageService.shared.pdfURL(for: path)
    }

    // MARK: - Severity Breakdown

    /// Returns the percentage distribution of issues by severity for the report.
    func severityBreakdown(for report: InspectionReport) -> [(severity: IssueSeverity, count: Int, percentage: Double)] {
        let issues = report.issues ?? []
        guard !issues.isEmpty else { return [] }

        let grouped = Dictionary(grouping: issues) { $0.severity }
        let total = Double(issues.count)

        return grouped
            .map { (severity: $0.key, count: $0.value.count, percentage: Double($0.value.count) / total) }
            .sorted { $0.severity.priority > $1.severity.priority }
    }

    // MARK: - Private Helpers

    /// Builds PDF export settings based on the current configuration and entitlements.
    private func buildExportSettings(for report: InspectionReport) -> PDFExportSettings {
        var settings = exportSettings

        // Apply Pro feature: watermark control
        if !EntitlementManager.shared.canAccessProFeature() {
            // Free users cannot disable watermark
            settings.includeWatermark = true
        }

        return settings
    }
}
