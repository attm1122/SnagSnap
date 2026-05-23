import SwiftData
import Foundation

@Model
final class InspectionArea {
    @Attribute(.unique) var id: UUID
    var name: String
    var sortOrder: Int
    var createdAt: Date

    @Relationship(inverse: \InspectionReport.areas)
    var report: InspectionReport?

    @Relationship(deleteRule: .cascade, inverse: \InspectionIssue.area)
    var issues: [InspectionIssue]? = []

    var issueList: [InspectionIssue] {
        issues ?? []
    }

    init(
        id: UUID = UUID(),
        name: String,
        sortOrder: Int = 0,
        report: InspectionReport? = nil
    ) {
        self.id = id
        self.name = name
        self.sortOrder = sortOrder
        self.createdAt = Date()
        self.report = report
    }
}
