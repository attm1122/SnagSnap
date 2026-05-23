// SnagSnap
// InspectionReport.swift
//
// The top-level model representing a complete property inspection report.

import Foundation
import SwiftData

/// Represents a full property inspection report.
/// Contains metadata, areas, and individual issues.
@Model
class InspectionReport {

    // MARK: - Stored Properties

    /// Unique identifier for the report.
    @Attribute(.unique) var id: UUID

    /// Title of the report (e.g. "123 Main St - Move In").
    var title: String

    /// Name of the property being inspected.
    var propertyName: String

    /// Full address of the property.
    var propertyAddress: String

    /// Raw string value of the `ReportType` (used for SwiftData persistence).
    var reportTypeRaw: String

    /// Name of the client who requested the inspection (optional).
    var clientName: String?

    /// Name of the inspector who performed the inspection (optional).
    var inspectorName: String?

    /// General notes applying to the entire report (optional).
    var generalNotes: String?

    /// The date the inspection was carried out.
    var inspectionDate: Date

    /// Timestamp when the report was first created.
    var createdAt: Date

    /// Timestamp when the report was last modified.
    var updatedAt: Date

    /// Raw string value of the `ReportStatus` (used for SwiftData persistence).
    var statusRaw: String

    // MARK: - Relationships

    /// All inspection areas within this report. Deleting a report cascades to delete its areas.
    @Relationship(deleteRule: .cascade) var areas: [InspectionArea]?

    /// All issues within this report (across all areas). Deleting a report cascades to delete its issues.
    @Relationship(deleteRule: .cascade) var issues: [InspectionIssue]?

    // MARK: - Codable Type / Status

    /// The report type (mapped from `reportTypeRaw`).
    var reportType: ReportType {
        get {
            ReportType(rawValue: reportTypeRaw) ?? .general
        }
        set {
            reportTypeRaw = newValue.rawValue
        }
    }

    /// The current status of the report (mapped from `statusRaw`).
    var status: ReportStatus {
        get {
            ReportStatus(rawValue: statusRaw) ?? .draft
        }
        set {
            statusRaw = newValue.rawValue
        }
    }

    // MARK: - Lifecycle

    /// Creates a new inspection report.
    ///
    /// - Parameters:
    ///   - title: Report title.
    ///   - propertyName: Name of the property.
    ///   - propertyAddress: Full property address.
    ///   - reportType: Category of inspection; defaults to `.general`.
    ///   - clientName: Optional client name.
    ///   - inspectorName: Optional inspector name.
    ///   - generalNotes: Optional general notes.
    ///   - inspectionDate: Date of inspection; defaults to the current date.
    ///   - status: Report lifecycle status; defaults to `.draft`.
    init(
        title: String,
        propertyName: String,
        propertyAddress: String,
        reportType: ReportType = .general,
        clientName: String? = nil,
        inspectorName: String? = nil,
        generalNotes: String? = nil,
        inspectionDate: Date = Date(),
        status: ReportStatus = .draft
    ) {
        self.id = UUID()
        self.title = title
        self.propertyName = propertyName
        self.propertyAddress = propertyAddress
        self.reportTypeRaw = reportType.rawValue
        self.clientName = clientName
        self.inspectorName = inspectorName
        self.generalNotes = generalNotes
        self.inspectionDate = inspectionDate
        self.createdAt = Date()
        self.updatedAt = Date()
        self.statusRaw = status.rawValue
    }

    // MARK: - Computed Properties

    /// The number of areas in this report.
    var areaCount: Int {
        areas?.count ?? 0
    }

    /// The total number of issues across all areas.
    var issueCount: Int {
        issues?.count ?? 0
    }

    /// The number of issues that are still open or in progress.
    var openIssueCount: Int {
        guard let issues = issues else { return 0 }
        return issues.filter { $0.status.isOpen }.count
    }

    /// The number of issues that have been fixed.
    var fixedIssueCount: Int {
        guard let issues = issues else { return 0 }
        return issues.filter { $0.status == .fixed }.count
    }

    /// The number of issues marked as urgent.
    var urgentIssueCount: Int {
        guard let issues = issues else { return 0 }
        return issues.filter { $0.severity == .urgent }.count
    }

    /// The number of issues with high or urgent severity.
    var highSeverityCount: Int {
        guard let issues = issues else { return 0 }
        return issues.filter { $0.severity == .high || $0.severity == .urgent }.count
    }

    /// The total number of photos across all issues in this report.
    var photoCount: Int {
        guard let issues = issues else { return 0 }
        return issues.reduce(0) { $0 + ($1.photos?.count ?? 0) }
    }

    /// A breakdown of issue counts grouped by severity, sorted from highest to lowest priority.
    var issueBreakdownBySeverity: [(severity: IssueSeverity, count: Int)] {
        guard let issues = issues else { return [] }
        let grouped = Dictionary(grouping: issues) { $0.severity }
        return grouped
            .map { (severity: $0.key, count: $0.value.count) }
            .sorted { $0.severity.priority > $1.severity.priority }
    }

    /// Whether the report is in a complete state (ready or already exported).
    var isComplete: Bool {
        status == .ready || status == .exported
    }

    /// A user-friendly formatted string of the inspection date (e.g. "23 May 2025").
    var displayDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: inspectionDate)
    }

    /// A concise summary description of the report for list views.
    var summaryDescription: String {
        let typeLabel = reportType.displayName
        let dateLabel = displayDate
        let areaLabel = areaCount == 1 ? "1 area" : "\(areaCount) areas"
        let issueLabel = issueCount == 1 ? "1 issue" : "\(issueCount) issues"
        return "\(typeLabel) \u{2022} \(dateLabel) \u{2022} \(areaLabel), \(issueLabel)"
    }
}
