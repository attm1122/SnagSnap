// SnagSnap
// InspectionArea.swift
//
// A distinct area or room within a property that is being inspected.

import Foundation
import SwiftData

/// Represents an area (room, zone, or exterior space) inside an inspection report.
/// Each area can contain multiple issues.
@Model
class InspectionArea {

    // MARK: - Stored Properties

    /// Unique identifier for the area.
    @Attribute(.unique) var id: UUID

    /// Human-readable name of the area (e.g. "Kitchen", "Master Bedroom").
    var name: String

    /// General notes about the area as a whole (optional).
    var notes: String?

    /// Timestamp when the area was created.
    var createdAt: Date

    /// Timestamp when the area was last modified.
    var updatedAt: Date

    // MARK: - Relationships

    /// The report this area belongs to.
    @Relationship(inverse: \InspectionReport.areas) var report: InspectionReport?

    /// The list of issues found in this area. Deleting an area nullifies the relationship on its issues.
    @Relationship(deleteRule: .nullify) var issues: [InspectionIssue]?

    // MARK: - Suggested Names

    /// Pre-defined area names offered to users when creating a new area.
    static let suggestedNames: [String] = [
        "Kitchen",
        "Bathroom",
        "Bedroom 1",
        "Bedroom 2",
        "Living Room",
        "Hallway",
        "Exterior",
        "Garage",
        "Garden",
        "Other"
    ]

    // MARK: - Lifecycle

    /// Creates a new inspection area.
    ///
    /// - Parameters:
    ///   - name: The name of the area.
    ///   - notes: Optional notes about the area.
    init(name: String, notes: String? = nil) {
        self.id = UUID()
        self.name = name
        self.notes = notes
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // MARK: - Computed Properties

    /// The number of issues recorded in this area.
    var issueCount: Int {
        issues?.count ?? 0
    }

    /// The total number of photos across all issues in this area.
    var photoCount: Int {
        guard let issues = issues else { return 0 }
        return issues.reduce(0) { $0 + ($1.photos?.count ?? 0) }
    }

    /// Whether this area has one or more issues.
    var hasIssues: Bool {
        issueCount > 0
    }
}
