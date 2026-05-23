// SnagSnap
// UserProfile.swift
//
// The inspector / company profile used across all reports.

import Foundation
import SwiftData

/// Represents the inspector's professional profile and company details.
/// A single profile record is used app-wide; it is not tied to any individual report.
@Model
class UserProfile {

    // MARK: - Stored Properties

    /// Unique identifier for the profile.
    @Attribute(.unique) var id: UUID

    /// Company or trading name displayed on reports.
    var companyName: String

    /// Name of the individual inspector.
    var inspectorName: String

    /// Contact phone number (optional).
    var phone: String?

    /// Contact email address (optional).
    var email: String?

    /// File-system path (or cloud ID) of the uploaded company logo.
    var logoPath: String?

    /// Timestamp when the profile was first created.
    var createdAt: Date

    /// Timestamp when the profile was last modified.
    var updatedAt: Date

    // MARK: - Lifecycle

    /// Creates a new user profile.
    ///
    /// - Parameters:
    ///   - companyName: Company or trading name.
    ///   - inspectorName: Inspector's full name.
    ///   - phone: Optional phone number.
    ///   - email: Optional email address.
    ///   - logoPath: Optional path/identifier for the company logo.
    init(
        companyName: String = "",
        inspectorName: String = "",
        phone: String? = nil,
        email: String? = nil,
        logoPath: String? = nil
    ) {
        self.id = UUID()
        self.companyName = companyName
        self.inspectorName = inspectorName
        self.phone = phone
        self.email = email
        self.logoPath = logoPath
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // MARK: - Computed Properties

    /// Returns the company name if available, otherwise the inspector name.
    var displayName: String {
        companyName.isEmpty ? inspectorName : companyName
    }

    /// Whether any contact information (phone or email) has been provided.
    var hasContactInfo: Bool {
        phone != nil || email != nil
    }
}
