import XCTest
@testable import SnagSnap

final class EnumTests: XCTestCase {
    func testReportTypeRawValuesMatchPersistenceContract() {
        XCTAssertEqual(ReportType.moveIn.rawValue, "move_in")
        XCTAssertEqual(ReportType.moveOut.rawValue, "move_out")
        XCTAssertEqual(ReportType.snagging.rawValue, "snagging")
        XCTAssertEqual(ReportType.cleaning.rawValue, "cleaning")
        XCTAssertEqual(ReportType.maintenance.rawValue, "maintenance")
        XCTAssertEqual(ReportType.airbnb.rawValue, "airbnb")
        XCTAssertEqual(ReportType.general.rawValue, "general")
    }

    func testReportStatusMetadataIsComplete() {
        for status in ReportStatus.allCases {
            XCTAssertEqual(status.id, status.rawValue)
            XCTAssertFalse(status.displayName.isEmpty)
            XCTAssertFalse(status.icon.isEmpty)
            _ = status.color
        }
    }

    func testIssueSeverityPrioritySortsFromLowToUrgent() {
        XCTAssertEqual(IssueSeverity.allCases.map(\.priority), [1, 2, 3, 4])
        XCTAssertEqual(IssueSeverity.urgent.icon, "flame.fill")
    }

    func testIssueStatusOpenSemantics() {
        XCTAssertTrue(IssueStatus.open.isOpen)
        XCTAssertTrue(IssueStatus.inProgress.isOpen)
        XCTAssertFalse(IssueStatus.fixed.isOpen)
        XCTAssertFalse(IssueStatus.notAnIssue.isOpen)
        XCTAssertFalse(IssueStatus.archived.isOpen)
    }
}
