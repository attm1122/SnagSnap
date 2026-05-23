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
    func generatePDF(for report: InspectionReport) {
        pdfState = .generating

        do {
            let data = try pdfService.generatePDF(for: report, settings: exportSettings)
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
