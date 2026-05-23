// SnagSnap
// IssuePhoto.swift
//
// A photo attached to an inspection issue, including optional annotation.

import Foundation
import SwiftData

/// Represents a photograph captured for a specific inspection issue.
/// Supports original, thumbnail, and annotated variants.
@Model
class IssuePhoto {

    // MARK: - Stored Properties

    /// Unique identifier for the photo record.
    @Attribute(.unique) var id: UUID

    /// File-system path or cloud identifier for the full-resolution original image.
    var originalImagePath: String

    /// File-system path or cloud identifier for the thumbnail variant.
    var thumbnailImagePath: String

    /// File-system path or cloud identifier for the annotated / marked-up image (if any).
    var annotatedImagePath: String?

    /// Optional user-provided caption or description of the photo.
    var caption: String?

    /// Timestamp when the photo was captured / added.
    var createdAt: Date

    /// Timestamp when the photo record was last modified.
    var updatedAt: Date

    // MARK: - Relationships

    /// The inspection issue this photo belongs to.
    @Relationship(inverse: \InspectionIssue.photos) var issue: InspectionIssue?

    // MARK: - Lifecycle

    /// Creates a new issue photo.
    ///
    /// - Parameters:
    ///   - originalImagePath: Path to the full-resolution image.
    ///   - thumbnailImagePath: Path to the thumbnail image.
    ///   - annotatedImagePath: Optional path to an annotated version.
    ///   - caption: Optional caption describing the photo.
    init(
        originalImagePath: String,
        thumbnailImagePath: String,
        annotatedImagePath: String? = nil,
        caption: String? = nil
    ) {
        self.id = UUID()
        self.originalImagePath = originalImagePath
        self.thumbnailImagePath = thumbnailImagePath
        self.annotatedImagePath = annotatedImagePath
        self.caption = caption
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // MARK: - Computed Properties

    /// Whether an annotated version of this photo exists.
    var hasAnnotation: Bool {
        annotatedImagePath != nil
    }
}
