import XCTest
@testable import SnagSnap

final class ModelTests: XCTestCase {
    func testReportCountsReflectRelationships() {
        let report = InspectionReport(
            title: "Move-in inspection",
            propertyName: "Flat 4",
            propertyAddress: "1 Test Street",
            reportType: .moveIn
        )
        let kitchen = InspectionArea(name: "Kitchen")
        let urgent = InspectionIssue(title: "Leaking tap", severity: .urgent, status: .open)
        let fixed = InspectionIssue(title: "Scuffed wall", severity: .low, status: .fixed)
        let photo = IssuePhoto(originalImagePath: "original.jpg", thumbnailImagePath: "thumb.jpg")

        urgent.photos = [photo]
        kitchen.issues = [urgent, fixed]
        report.areas = [kitchen]
        report.issues = [urgent, fixed]

        XCTAssertEqual(report.areaCount, 1)
        XCTAssertEqual(report.issueCount, 2)
        XCTAssertEqual(report.openIssueCount, 1)
        XCTAssertEqual(report.fixedIssueCount, 1)
        XCTAssertEqual(report.urgentIssueCount, 1)
        XCTAssertEqual(report.highSeverityCount, 1)
        XCTAssertEqual(report.photoCount, 1)
        XCTAssertEqual(kitchen.issueCount, 2)
        XCTAssertEqual(kitchen.photoCount, 1)
    }

    func testIssueComputedPropertiesUseCurrentStatusAndPhotos() {
        let issue = InspectionIssue(
            title: "Damaged cabinet",
            notes: String(repeating: "A", count: 120),
            severity: .high,
            status: .notAnIssue
        )
        issue.photos = [
            IssuePhoto(
                originalImagePath: "original.jpg",
                thumbnailImagePath: "thumb.jpg",
                annotatedImagePath: "annotated.jpg"
            )
        ]

        XCTAssertTrue(issue.isResolved)
        XCTAssertTrue(issue.hasPhotos)
        XCTAssertEqual(issue.photoCount, 1)
        XCTAssertEqual(issue.shortNotes.count, 80)
        XCTAssertTrue(issue.shortNotes.hasSuffix("\u{2026}"))
        XCTAssertTrue(issue.photos?.first?.hasAnnotation == true)
    }

    func testReportCompletionUsesReadyAndExportedStatuses() {
        let report = InspectionReport(
            title: "Snagging",
            propertyName: "New Build",
            propertyAddress: "2 Test Street"
        )

        XCTAssertFalse(report.isComplete)
        report.status = .ready
        XCTAssertTrue(report.isComplete)
        report.status = .exported
        XCTAssertTrue(report.isComplete)
    }
}
