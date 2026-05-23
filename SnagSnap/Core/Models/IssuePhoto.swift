import SwiftData
import Foundation
import UIKit

@Model
final class IssuePhoto {
    @Attribute(.unique) var id: UUID
    var imageData: Data?
    var caption: String
    var createdAt: Date
    var annotationData: Data?
    var sortOrder: Int

    @Relationship(inverse: \InspectionIssue.photos)
    var issue: InspectionIssue?

    @Transient
    var uiImage: UIImage? {
        guard let imageData else { return nil }
        return UIImage(data: imageData)
    }

    init(
        id: UUID = UUID(),
        imageData: Data? = nil,
        caption: String = "",
        annotationData: Data? = nil,
        sortOrder: Int = 0,
        issue: InspectionIssue? = nil
    ) {
        self.id = id
        self.imageData = imageData
        self.caption = caption
        self.annotationData = annotationData
        self.sortOrder = sortOrder
        self.createdAt = Date()
        self.issue = issue
    }
}
