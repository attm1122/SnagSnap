import SwiftData
import Foundation

@Model
final class UserProfile {
    @Attribute(.unique) var id: UUID
    var name: String
    var email: String
    var phone: String?
    var company: String?
    var jobTitle: String?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String = "",
        email: String = "",
        phone: String? = nil,
        company: String? = nil,
        jobTitle: String? = nil
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.phone = phone
        self.company = company
        self.jobTitle = jobTitle
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
