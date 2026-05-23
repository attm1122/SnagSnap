import XCTest
@testable import SnagSnap

// MARK: - IssueLogicTests
// Comprehensive tests for InspectionIssue model, severity, status logic, and edge cases

final class IssueLogicTests: XCTestCase {

    // MARK: - Test Data Helpers

    private func makeIssue(
        title: String = "Test Issue",
        notes: String? = nil,
        severity: IssueSeverity = .medium,
        status: IssueStatus = .open,
        photos: [IssuePhoto] = []
    ) -> InspectionIssue {
        InspectionIssue(
            title: title,
            notes: notes,
            severity: severity,
            status: status,
            photos: photos
        )
    }

    private func makePhoto(
        originalPath: String = "/tmp/test.jpg",
        thumbnailPath: String = "/tmp/test_thumb.jpg",
        annotatedPath: String? = nil,
        caption: String? = nil
    ) -> IssuePhoto {
        IssuePhoto(
            originalImagePath: originalPath,
            thumbnailImagePath: thumbnailPath,
            annotatedImagePath: annotatedPath,
            caption: caption
        )
    }

    // MARK: - Creation Tests

    func testIssueCreation() {
        let issue = makeIssue(
            title: "Cracked tile in bathroom",
            notes: "Approximately 2-inch crack near the sink",
            severity: .high,
            status: .open
        )

        XCTAssertEqual(issue.title, "Cracked tile in bathroom")
        XCTAssertEqual(issue.notes, "Approximately 2-inch crack near the sink")
        XCTAssertEqual(issue.severity, .high)
        XCTAssertEqual(issue.status, .open)
        XCTAssertNotNil(issue.createdAt)
    }

    func testIssueCreationWithDefaults() {
        let issue = InspectionIssue()

        XCTAssertFalse(issue.title.isEmpty)
        XCTAssertNil(issue.notes)
        XCTAssertNotNil(issue.createdAt)
    }

    // MARK: - Severity Tests

    func testIssueSeverityPriority() {
        XCTAssertEqual(IssueSeverity.low.priority, 1, "Low severity should have priority 1")
        XCTAssertEqual(IssueSeverity.medium.priority, 2, "Medium severity should have priority 2")
        XCTAssertEqual(IssueSeverity.high.priority, 3, "High severity should have priority 3")
        XCTAssertEqual(IssueSeverity.urgent.priority, 4, "Urgent severity should have priority 4")
    }

    func testIssueSeverityPriorityStrictlyOrdered() {
        let severities: [IssueSeverity] = [.low, .medium, .high, .urgent]
        for i in 0..<(severities.count - 1) {
            XCTAssertLessThan(
                severities[i].priority,
                severities[i + 1].priority,
                "\(severities[i]) should have lower priority than \(severities[i + 1])"
            )
        }
    }

    func testIssueSeverityColors() {
        // All severities should produce a valid Color (no crash)
        for severity in IssueSeverity.allCases {
            let color = severity.color
            XCTAssertNotNil(color, "IssueSeverity '\(severity)' should have a valid color")
        }
    }

    func testIssueSeverityInitialization() {
        let lowIssue = makeIssue(severity: .low)
        let mediumIssue = makeIssue(severity: .medium)
        let highIssue = makeIssue(severity: .high)
        let urgentIssue = makeIssue(severity: .urgent)

        XCTAssertEqual(lowIssue.severity, .low)
        XCTAssertEqual(mediumIssue.severity, .medium)
        XCTAssertEqual(highIssue.severity, .high)
        XCTAssertEqual(urgentIssue.severity, .urgent)
    }

    func testIssueSeverityRawValueRoundTrip() {
        for severity in IssueSeverity.allCases {
            let issue = makeIssue(severity: severity)
            XCTAssertEqual(issue.severityRaw, severity.rawValue)
            XCTAssertEqual(issue.severity, severity)
        }
    }

    // MARK: - Status Tests

    func testIssueStatusDisplayNames() {
        for status in IssueStatus.allCases {
            XCTAssertFalse(status.displayName.isEmpty,
                           "IssueStatus '\(status)' should have a non-empty display name")
        }
    }

    func testIssueStatusIsOpen() {
        XCTAssertTrue(IssueStatus.open.isOpen, "Open should be considered open")
        XCTAssertTrue(IssueStatus.inProgress.isOpen, "InProgress should be considered open")
        XCTAssertFalse(IssueStatus.fixed.isOpen, "Fixed should NOT be considered open")
        XCTAssertFalse(IssueStatus.notAnIssue.isOpen, "NotAnIssue should NOT be considered open")
        XCTAssertFalse(IssueStatus.archived.isOpen, "Archived should NOT be considered open")
    }

    func testIssueStatusIsResolved() {
        let fixedIssue = makeIssue(status: .fixed)
        let notAnIssue = makeIssue(status: .notAnIssue)
        let openIssue = makeIssue(status: .open)
        let inProgressIssue = makeIssue(status: .inProgress)
        let archivedIssue = makeIssue(status: .archived)

        XCTAssertTrue(fixedIssue.isResolved, "Fixed issue should be resolved")
        XCTAssertTrue(notAnIssue.isResolved, "NotAnIssue should be resolved")
        XCTAssertFalse(openIssue.isResolved, "Open issue should NOT be resolved")
        XCTAssertFalse(inProgressIssue.isResolved, "InProgress issue should NOT be resolved")
        XCTAssertFalse(archivedIssue.isResolved, "Archived issue should NOT be resolved")
    }

    func testIssueStatusTransitions() {
        let issue = makeIssue(status: .open)
        XCTAssertEqual(issue.status, .open)

        issue.status = .inProgress
        XCTAssertEqual(issue.status, .inProgress)

        issue.status = .fixed
        XCTAssertEqual(issue.status, .fixed)

        issue.status = .notAnIssue
        XCTAssertEqual(issue.status, .notAnIssue)

        issue.status = .archived
        XCTAssertEqual(issue.status, .archived)
    }

    func testIssueStatusRawValueRoundTrip() {
        for status in IssueStatus.allCases {
            let issue = makeIssue(status: status)
            XCTAssertEqual(issue.statusRaw, status.rawValue)
            XCTAssertEqual(issue.status, status)
        }
    }

    // MARK: - Resolved Logic Tests

    func testAllResolvedStatuses() {
        let resolvedStatuses: [IssueStatus] = [.fixed, .notAnIssue]
        for status in resolvedStatuses {
            let issue = makeIssue(status: status)
            XCTAssertTrue(issue.isResolved, "Status '\(status)' should be resolved")
        }
    }

    func testAllUnresolvedStatuses() {
        let unresolvedStatuses: [IssueStatus] = [.open, .inProgress, .archived]
        for status in unresolvedStatuses {
            let issue = makeIssue(status: status)
            XCTAssertFalse(issue.isResolved, "Status '\(status)' should NOT be resolved")
        }
    }

    func testResolvedIssuesAreNotOpen() {
        // Cross-check: resolved issues should not be "open"
        let fixedIssue = makeIssue(status: .fixed)
        let notAnIssue = makeIssue(status: .notAnIssue)

        XCTAssertFalse(fixedIssue.status.isOpen)
        XCTAssertFalse(notAnIssue.status.isOpen)
    }

    func testUnresolvedIssuesThatAreOpen() {
        // Cross-check: unresolved issues that are "in progress" should still be isOpen
        let inProgressIssue = makeIssue(status: .inProgress)
        XCTAssertTrue(inProgressIssue.status.isOpen)
        XCTAssertFalse(inProgressIssue.isResolved)
    }

    // MARK: - Photo Count Tests

    func testIssuePhotoCount() {
        let photo1 = makePhoto()
        let photo2 = makePhoto(originalPath: "/tmp/test2.jpg", thumbnailPath: "/tmp/test2_thumb.jpg")
        let issue = makeIssue(photos: [photo1, photo2])

        XCTAssertEqual(issue.photoCount, 2)
    }

    func testIssuePhotoCountZero() {
        let issue = makeIssue(photos: [])
        XCTAssertEqual(issue.photoCount, 0)
    }

    func testIssuePhotoCountWithNilPhotos() {
        let issue = makeIssue()
        XCTAssertEqual(issue.photoCount, 0)
    }

    func testIssuePhotoCountWithManyPhotos() {
        let photos = (1...20).map { makePhoto(originalPath: "/tmp/img\($0).jpg", thumbnailPath: "/tmp/img\($0)_thumb.jpg") }
        let issue = makeIssue(photos: photos)

        XCTAssertEqual(issue.photoCount, 20)
    }

    // MARK: - Notes Tests

    func testIssueWithNotes() {
        let issue = makeIssue(notes: "This is a detailed note about the issue")
        XCTAssertEqual(issue.notes, "This is a detailed note about the issue")
    }

    func testIssueWithNilNotes() {
        let issue = makeIssue(notes: nil)
        XCTAssertNil(issue.notes)
    }

    func testIssueWithEmptyNotes() {
        let issue = makeIssue(notes: "")
        XCTAssertEqual(issue.notes, "")
    }

    // MARK: - Title Tests

    func testIssueWithEmptyTitle() {
        let issue = makeIssue(title: "")
        XCTAssertEqual(issue.title, "")
    }

    func testIssueWithLongTitle() {
        let longTitle = String(repeating: "A", count: 500)
        let issue = makeIssue(title: longTitle)
        XCTAssertEqual(issue.title.count, 500)
    }

    func testIssueWithSpecialCharactersInTitle() {
        let specialTitle = "Issue: Kitchen <sink> & \"pipe\""
        let issue = makeIssue(title: specialTitle)
        XCTAssertEqual(issue.title, specialTitle)
    }

    // MARK: - Edge Cases

    func testIssueCreatedAtIsNotNil() {
        let issue = makeIssue()
        XCTAssertNotNil(issue.createdAt, "createdAt should never be nil")
    }

    func testIssueCreatedAtIsRecent() {
        let before = Date()
        let issue = makeIssue()
        let after = Date()

        XCTAssertGreaterThanOrEqual(issue.createdAt, before)
        XCTAssertLessThanOrEqual(issue.createdAt, after)
    }

    func testIssueWithUrgentSeverityIsHighestPriority() {
        let urgentIssue = makeIssue(severity: .urgent)
        XCTAssertEqual(urgentIssue.severity.priority, 4)
    }

    func testIssueSeverityCanChange() {
        let issue = makeIssue(severity: .low)
        XCTAssertEqual(issue.severity, .low)

        issue.severity = .urgent
        XCTAssertEqual(issue.severity, .urgent)
        XCTAssertEqual(issue.severityRaw, "urgent")
    }

    func testIssueStatusCanChangeMultipleTimes() {
        let issue = makeIssue(status: .open)

        issue.status = .inProgress
        XCTAssertEqual(issue.status, .inProgress)

        issue.status = .fixed
        XCTAssertEqual(issue.status, .fixed)

        issue.status = .open
        XCTAssertEqual(issue.status, .open)
    }

    // MARK: - Severity + Status Combination Tests

    func testAllSeverityStatusCombinations() {
        // Ensure no combination crashes or produces invalid state
        for severity in IssueSeverity.allCases {
            for status in IssueStatus.allCases {
                let issue = makeIssue(severity: severity, status: status)
                XCTAssertEqual(issue.severity, severity)
                XCTAssertEqual(issue.status, status)
                XCTAssertNotNil(issue.createdAt)
            }
        }
    }

    // MARK: - Photo Relationship Tests

    func testIssuePhotoRelationship() {
        let photo = makePhoto(caption: "Close-up of damage")
        let issue = makeIssue(photos: [photo])

        XCTAssertEqual(issue.photos?.count ?? 0, 1)
        XCTAssertEqual(issue.photos?.first?.caption, "Close-up of damage")
    }

    func testIssuePhotoHasAnnotation() {
        let photoWithAnnotation = makePhoto(annotatedPath: "/tmp/test_annotated.jpg")
        let photoWithoutAnnotation = makePhoto(annotatedPath: nil)

        XCTAssertTrue(photoWithAnnotation.hasAnnotation)
        XCTAssertFalse(photoWithoutAnnotation.hasAnnotation)
    }

    func testIssueWithAnnotatedPhotos() {
        let photo1 = makePhoto(annotatedPath: "/tmp/anno1.jpg")
        let photo2 = makePhoto(annotatedPath: nil)
        let issue = makeIssue(photos: [photo1, photo2])

        XCTAssertTrue(issue.photos?[0].hasAnnotation ?? false)
        XCTAssertFalse(issue.photos?[1].hasAnnotation ?? true)
    }

    // MARK: - Backing Raw Value Tests

    func testSeverityRawBackingSync() {
        let issue = makeIssue(severity: .high)
        XCTAssertEqual(issue.severityRaw, "high")

        issue.severity = .medium
        XCTAssertEqual(issue.severityRaw, "medium")
    }

    func testStatusRawBackingSync() {
        let issue = makeIssue(status: .inProgress)
        XCTAssertEqual(issue.statusRaw, "inProgress")

        issue.status = .archived
        XCTAssertEqual(issue.statusRaw, "archived")
    }
}
