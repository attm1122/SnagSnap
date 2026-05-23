// SnagSnap
// Enums.swift
//
// All domain enums used across the SnagSnap app.

import SwiftUI
import SwiftData

// MARK: - ReportStatus

/// Represents the lifecycle status of an inspection report.
enum ReportStatus: String, Codable, CaseIterable, Identifiable {
    case draft = "draft"
    case ready = "ready"
    case exported = "exported"
    case archived = "archived"

    var id: String { rawValue }

    /// User-facing display name for this status.
    var displayName: String {
        switch self {
        case .draft: return "Draft"
        case .ready: return "Ready"
        case .exported: return "Exported"
        case .archived: return "Archived"
        }
    }

    /// Semantic color used to represent this status in the UI.
    var color: Color {
        switch self {
        case .draft: return .orange
        case .ready: return .blue
        case .exported: return .green
        case .archived: return .gray
        }
    }

    /// SF Symbol name representing this status.
    var icon: String {
        switch self {
        case .draft: return "pencil.circle.fill"
        case .ready: return "checkmark.circle.fill"
        case .exported: return "square.and.arrow.up.circle.fill"
        case .archived: return "archivebox.circle.fill"
        }
    }
}

// MARK: - ReportType

/// Represents the category of an inspection report.
enum ReportType: String, Codable, CaseIterable, Identifiable {
    case moveIn = "move_in"
    case moveOut = "move_out"
    case snagging = "snagging"
    case cleaning = "cleaning"
    case maintenance = "maintenance"
    case airbnb = "airbnb"
    case general = "general"

    var id: String { rawValue }

    /// User-facing display name for this report type.
    var displayName: String {
        switch self {
        case .moveIn: return "Move In"
        case .moveOut: return "Move Out"
        case .snagging: return "Snagging"
        case .cleaning: return "Cleaning"
        case .maintenance: return "Maintenance"
        case .airbnb: return "Airbnb"
        case .general: return "General"
        }
    }

    /// SF Symbol name representing this report type.
    var icon: String {
        switch self {
        case .moveIn: return "arrow.down.circle.fill"
        case .moveOut: return "arrow.up.circle.fill"
        case .snagging: return "magnifyingglass.circle.fill"
        case .cleaning: return "sparkles"
        case .maintenance: return "wrench.adjustable.fill"
        case .airbnb: return "house.circle.fill"
        case .general: return "clipboard.fill"
        }
    }

    /// Short description explaining the purpose of this report type.
    var description: String {
        switch self {
        case .moveIn:
            return "Document property condition at the start of a tenancy."
        case .moveOut:
            return "Record property condition at the end of a tenancy."
        case .snagging:
            return "Identify defects and unfinished work in new builds."
        case .cleaning:
            return "Assess cleanliness and hygiene standards."
        case .maintenance:
            return "Track repairs and ongoing maintenance tasks."
        case .airbnb:
            return "Quick inspection for short-term rental turnovers."
        case .general:
            return "Flexible inspection for any purpose."
        }
    }
}

// MARK: - IssueSeverity

/// Represents the severity level of an inspection issue.
enum IssueSeverity: String, Codable, CaseIterable, Identifiable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case urgent = "urgent"

    var id: String { rawValue }

    /// User-facing display name for this severity level.
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .urgent: return "Urgent"
        }
    }

    /// Semantic color representing this severity in the UI.
    var color: Color {
        switch self {
        case .low: return .cyan
        case .medium: return .yellow
        case .high: return .orange
        case .urgent: return .red
        }
    }

    /// SF Symbol name representing this severity.
    var icon: String {
        switch self {
        case .low: return "minus.circle.fill"
        case .medium: return "exclamationmark.triangle.fill"
        case .high: return "exclamationmark.octagon.fill"
        case .urgent: return "flame.fill"
        }
    }

    /// Numeric priority for sorting; higher values indicate greater urgency.
    var priority: Int {
        switch self {
        case .low: return 1
        case .medium: return 2
        case .high: return 3
        case .urgent: return 4
        }
    }
}

// MARK: - IssueStatus

/// Represents the resolution status of an inspection issue.
enum IssueStatus: String, Codable, CaseIterable, Identifiable {
    case open = "open"
    case inProgress = "in_progress"
    case fixed = "fixed"
    case notAnIssue = "not_an_issue"
    case archived = "archived"

    var id: String { rawValue }

    /// User-facing display name for this status.
    var displayName: String {
        switch self {
        case .open: return "Open"
        case .inProgress: return "In Progress"
        case .fixed: return "Fixed"
        case .notAnIssue: return "Not an Issue"
        case .archived: return "Archived"
        }
    }

    /// Semantic color representing this status in the UI.
    var color: Color {
        switch self {
        case .open: return .red
        case .inProgress: return .blue
        case .fixed: return .green
        case .notAnIssue: return .gray
        case .archived: return .gray
        }
    }

    /// SF Symbol name representing this status.
    var icon: String {
        switch self {
        case .open: return "circle.fill"
        case .inProgress: return "arrow.triangle.2.circlepath.circle.fill"
        case .fixed: return "checkmark.circle.fill"
        case .notAnIssue: return "slash.circle.fill"
        case .archived: return "archivebox.fill"
        }
    }

    /// Whether the issue is still considered open (i.e. not yet resolved).
    var isOpen: Bool {
        self == .open || self == .inProgress
    }
}
