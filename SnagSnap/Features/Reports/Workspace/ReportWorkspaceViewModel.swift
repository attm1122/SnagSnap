// SnagSnap
// ReportWorkspaceViewModel.swift
//
// View model managing the report workspace state, issue filtering/sorting,
// PDF generation, and export settings.

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

/// Tracks the current state of PDF generation.
enum PDFGenerationState: Equatable {
    case idle
    case generating
    case generated(Data)
    case error(String)
}

// MARK: - ReportWorkspaceViewModel

/// View model for the report workspace, managing tab selection, issue filtering,
/// sorting, PDF generation, and export settings.
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

    /// Export settings for PDF generation.
    var exportSettings = PDFExportSettings()

    /// Whether the share sheet is presented.
    var showShareSheet = false

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
        if case .generating = pdfState {
            return true
        }
        return false
    }

    /// Whether a PDF has been successfully generated and is ready to share.
    var canSharePDF: Bool {
        if case .generated = pdfState {
            return true
        }
        return false
    }

    // MARK: - PDF Actions

    /// Generates a PDF for the given report using current export settings.
    /// Saves the PDF to disk and updates the report model with the PDF reference.
    func generatePDF(for report: InspectionReport, modelContext: ModelContext) {
        pdfState = .generating

        do {
            let data = try pdfService.generatePDF(for: report, settings: exportSettings)

            // Save PDF to disk and update report
            let filename = FileStorageService.shared.pdfFilename(for: report.id)
            let pdfURL = try FileStorageService.shared.savePDF(data, filename: filename)
            self.latestPDFURL = pdfURL

            // Update the report model with PDF reference
            report.latestPDFPath = filename
            report.lastExportedAt = Date()
            report.status = .exported
            try modelContext.save()

            pdfState = .generated(data)
            pdfDataToShare = data
        } catch {
            pdfState = .error(error.localizedDescription)
        }
    }

    /// Resets the PDF generation state to idle.
    func resetPDFState() {
        pdfState = .idle
        pdfDataToShare = nil
    }

    /// Prepares the share sheet with generated PDF data.
    func prepareShare() {
        if case .generated(let data) = pdfState {
            pdfDataToShare = data
            showShareSheet = true
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

    /// Shares the latest generated PDF for the report.
    func shareLatestPDF(for report: InspectionReport) {
        guard let path = report.latestPDFPath,
              let pdfData = FileStorageService.shared.loadPDF(named: path) else {
            return
        }
        ShareService.shared.sharePDF(pdfData, reportTitle: report.title)
    }

    /// Checks for an existing PDF on initialization and restores the state if found.
    func checkForExistingPDF(for report: InspectionReport) {
        guard let path = report.latestPDFPath,
              FileStorageService.shared.pdfExists(named: path),
              let data = FileStorageService.shared.loadPDF(named: path) else {
            return
        }
        pdfState = .generated(data)
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
}
