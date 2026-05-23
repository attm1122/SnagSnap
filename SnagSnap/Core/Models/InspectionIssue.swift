import SwiftData
import Foundation

enum IssueStatus: String, CaseIterable, Codable {
    case open = "Open"
    case inProgress = "In Progress"
    case resolved = "Resolved"
}

enum IssueSeverity: String, CaseIterable, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"
}

@Model
final class InspectionIssue {
    @Attribute(.unique) var id: UUID
    var title: String
    var issueDescription: String
    var statusRaw: String
    var severityRaw: String
    var createdAt: Date
    var updatedAt: Date
    var sortOrder: Int

    var status: IssueStatus {
        get { IssueStatus(rawValue: statusRaw) ?? .open }
        set { statusRaw = newValue.rawValue }
    }

    var severity: IssueSeverity {
        get { IssueSeverity(rawValue: severityRaw) ?? .medium }
        set { severityRaw = newValue.rawValue }
    }

    @Relationship(inverse: \InspectionArea.issues)
    var area: InspectionArea?

    @Relationship(deleteRule: .cascade, inverse: \IssuePhoto.issue)
    var photos: [IssuePhoto]? = []

    var photoList: [IssuePhoto] {
        photos ?? []
    }

    init(
        id: UUID = UUID(),
        title: String,
        issueDescription: String = "",
        status: IssueStatus = .open,
        severity: IssueSeverity = .medium,
        sortOrder: Int = 0,
        area: InspectionArea? = nil
    ) {
        self.id = id
        self.title = title
        self.issueDescription = issueDescription
        self.statusRaw = status.rawValue
        self.severityRaw = severity.rawValue
        self.sortOrder = sortOrder
        self.createdAt = Date()
        self.updatedAt = Date()
        self.area = area
    }
}
