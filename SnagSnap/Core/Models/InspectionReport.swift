import SwiftData
import Foundation

enum ReportStatus: String, CaseIterable, Codable {
    case draft = "Draft"
    case inProgress = "In Progress"
    case completed = "Completed"
    case archived = "Archived"
}

@Model
final class InspectionReport {
    @Attribute(.unique) var id: UUID
    var title: String
    var address: String
    var clientName: String
    var statusRaw: String
    var createdAt: Date
    var updatedAt: Date
    var notes: String?
    var useCase: String

    var status: ReportStatus {
        get { ReportStatus(rawValue: statusRaw) ?? .draft }
        set { statusRaw = newValue.rawValue }
    }

    @Relationship(deleteRule: .cascade, inverse: \InspectionArea.report)
    var areas: [InspectionArea]? = []

    var areaList: [InspectionArea] {
        areas ?? []
    }

    init(
        id: UUID = UUID(),
        title: String,
        address: String = "",
        clientName: String = "",
        status: ReportStatus = .draft,
        notes: String? = nil,
        useCase: String = ""
    ) {
        self.id = id
        self.title = title
        self.address = address
        self.clientName = clientName
        self.statusRaw = status.rawValue
        self.createdAt = Date()
        self.updatedAt = Date()
        self.notes = notes
        self.useCase = useCase
    }
}
