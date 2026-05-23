// SnagSnap
// InspectionIssue.swift
//
// An individual issue (defect, observation, task) found during an inspection.

import Foundation
import SwiftData

/// Represents a single issue discovered during a property inspection.
/// Each issue has a severity, status, optional notes, and can have multiple photos.
@Model
class InspectionIssue {

    // MARK: - Stored Properties

    /// Unique identifier for the issue.
    @Attribute(.unique) var id: UUID

    /// Short title summarising the issue (e.g. "Cracked kitchen tile").
    var title: String

    /// Detailed notes or description of the issue (optional).
    var notes: String?

    /// Raw string value of the `IssueSeverity` (used for SwiftData persistence).
    var severityRaw: String

    /// Raw string value of the `IssueStatus` (used for SwiftData persistence).
    var statusRaw: String

    /// Timestamp when the issue was created.
    var createdAt: Date

    /// Timestamp when the issue was last modified.
    var updatedAt: Date

    // MARK: - Relationships

    /// The report this issue belongs to.
    @Relationship(inverse: \InspectionReport.issues) var report: InspectionReport?

    /// The inspection area (room / zone) where this issue was found.
    @Relationship(inverse: \InspectionArea.issues) var area: InspectionArea?

    /// All photos captured for this issue. Deleting an issue cascades to delete its photos.
    @Relationship(deleteRule: .cascade) var photos: [IssuePhoto]?

    // MARK: - Codable Severity / Status

    /// The severity level of this issue (mapped from `severityRaw`).
    var severity: IssueSeverity {
        get {
            IssueSeverity(rawValue: severityRaw) ?? .medium
        }
        set {
            severityRaw = newValue.rawValue
        }
    }

    /// The current resolution status of this issue (mapped from `statusRaw`).
    var status: IssueStatus {
        get {
            IssueStatus(rawValue: statusRaw) ?? .open
        }
        set {
            statusRaw = newValue.rawValue
        }
    }

    // MARK: - Lifecycle

    /// Creates a new inspection issue.
    ///
    /// - Parameters:
    ///   - title: Short descriptive title.
    ///   - notes: Optional detailed notes.
    ///   - severity: Severity level; defaults to `.medium`.
    ///   - status: Resolution status; defaults to `.open`.
    init(
        title: String,
        notes: String? = nil,
        severity: IssueSeverity = .medium,
        status: IssueStatus = .open
    ) {
        self.id = UUID()
        self.title = title
        self.notes = notes
        self.severityRaw = severity.rawValue
        self.statusRaw = status.rawValue
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // MARK: - Computed Properties

    /// The number of photos attached to this issue.
    var photoCount: Int {
        photos?.count ?? 0
    }

    /// Whether this issue has at least one photo.
    var hasPhotos: Bool {
        photoCount > 0
    }

    /// A truncated version of the notes suitable for list previews (max ~80 characters).
    var shortNotes: String {
        guard let notes = notes, !notes.isEmpty else { return "" }
        let maxLength = 80
        if notes.count <= maxLength {
            return notes
        }
        let prefix = notes.prefix(maxLength - 1)
        return String(prefix) + "\u{2026}"  // "…"
    }

    /// Whether the issue is considered resolved (fixed or marked as not an issue).
    var isResolved: Bool {
        status == .fixed || status == .notAnIssue
    }
}
