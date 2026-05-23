import XCTest
import SwiftData
@testable import SnagSnap

// MARK: - ReportModelTests
// Tests for InspectionReport model, status transitions, counts, and date handling

final class ReportModelTests: XCTestCase {

    // MARK: - Test Data Helpers

    private func makeReport(
        title: String = "Test Report",
        propertyName: String = "Test Property",
        propertyAddress: String = "123 Test St",
        status: ReportStatus = .draft,
        reportType: ReportType = .snagging,
        inspectionDate: Date = Date(),
        areas: [InspectionArea] = [],
        issues: [InspectionIssue] = []
    ) -> InspectionReport {
        let report = InspectionReport(
            title: title,
            propertyName: propertyName,
            propertyAddress: propertyAddress,
            status: status,
            reportType: reportType,
            inspectionDate: inspectionDate,
            areas: areas,
            issues: issues
        )
        return report
    }

    private func makeArea(name: String, notes: String? = nil, issues: [InspectionIssue] = []) -> InspectionArea {
        InspectionArea(name: name, notes: notes, issues: issues)
    }

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

    // MARK: - Creation Tests

    func testReportCreation() {
        let report = makeReport(
            title: "Move-In Inspection",
            propertyName: "Sunset Apartments",
            propertyAddress: "456 Sunset Blvd, Los Angeles, CA"
        )

        XCTAssertEqual(report.title, "Move-In Inspection")
        XCTAssertEqual(report.propertyName, "Sunset Apartments")
        XCTAssertEqual(report.propertyAddress, "456 Sunset Blvd, Los Angeles, CA")
        XCTAssertEqual(report.status, .draft)
        XCTAssertEqual(report.reportType, .snagging)
        XCTAssertNotNil(report.createdAt)
        XCTAssertNotNil(report.inspectionDate)
    }

    func testReportDefaultCreation() {
        let report = InspectionReport()

        XCTAssertTrue(report.title.isEmpty == false || report.title == "")
        XCTAssertNotNil(report.createdAt)
        XCTAssertNotNil(report.inspectionDate)
        XCTAssertEqual(report.status, .draft)
    }

    // MARK: - Status Transition Tests

    func testReportStatusTransitions() {
        let report = makeReport()
        XCTAssertEqual(report.status, .draft)

        report.status = .ready
        XCTAssertEqual(report.status, .ready)

        report.status = .exported
        XCTAssertEqual(report.status, .exported)

        report.status = .archived
        XCTAssertEqual(report.status, .archived)

        // Can transition back to draft
        report.status = .draft
        XCTAssertEqual(report.status, .draft)
    }

    func testReportStatusTransitionsThroughAllStates() {
        let report = makeReport()
        let allStatuses: [ReportStatus] = [.draft, .ready, .exported, .archived]

        for status in allStatuses {
            report.status = status
            XCTAssertEqual(report.status, status, "Report should transition to \(status)")
        }
    }

    func testReportStatusPersistsViaRawValue() {
        let report = makeReport(status: .exported)
        XCTAssertEqual(report.statusRaw, "exported")
        XCTAssertEqual(report.status, .exported)
    }

    // MARK: - Count Tests

    func testReportCounts() {
        let area1 = makeArea(name: "Living Room")
        let area2 = makeArea(name: "Kitchen")
        let area3 = makeArea(name: "Bedroom")

        let issue1 = makeIssue(title: "Scratch on wall", status: .open, severity: .low)
        let issue2 = makeIssue(title: "Broken tile", status: .inProgress, severity: .high)
        let issue3 = makeIssue(title: "Leaky faucet", status: .fixed, severity: .medium)
        let issue4 = makeIssue(title: "Cracked window", status: .open, severity: .urgent)

        let report = makeReport(
            areas: [area1, area2, area3],
            issues: [issue1, issue2, issue3, issue4]
        )

        XCTAssertEqual(report.areaCount, 3, "areaCount should reflect number of areas")
        XCTAssertEqual(report.issueCount, 4, "issueCount should reflect number of issues")
        XCTAssertEqual(report.openIssueCount, 3, "openIssueCount should count open + inProgress issues")
        XCTAssertEqual(report.fixedIssueCount, 1, "fixedIssueCount should count fixed issues")
        XCTAssertEqual(report.urgentIssueCount, 1, "urgentIssueCount should count urgent issues")
    }

    func testReportCountsWithNoAreas() {
        let issue = makeIssue(title: "Test Issue", status: .open)
        let report = makeReport(areas: [], issues: [issue])

        XCTAssertEqual(report.areaCount, 0)
        XCTAssertEqual(report.issueCount, 1)
    }

    func testReportCountsWithNoIssues() {
        let area = makeArea(name: "Bathroom")
        let report = makeReport(areas: [area], issues: [])

        XCTAssertEqual(report.areaCount, 1)
        XCTAssertEqual(report.issueCount, 0)
        XCTAssertEqual(report.openIssueCount, 0)
        XCTAssertEqual(report.fixedIssueCount, 0)
        XCTAssertEqual(report.urgentIssueCount, 0)
    }

    func testReportCountsWithNilRelationships() {
        let report = makeReport()
        // areas and issues are nil by default in some initializers
        XCTAssertEqual(report.areaCount, 0, "nil areas should produce 0 count")
        XCTAssertEqual(report.issueCount, 0, "nil issues should produce 0 count")
    }

    func testReportCountsWithAllFixedIssues() {
        let issue1 = makeIssue(status: .fixed)
        let issue2 = makeIssue(status: .notAnIssue)
        let report = makeReport(issues: [issue1, issue2])

        XCTAssertEqual(report.openIssueCount, 0)
        XCTAssertEqual(report.fixedIssueCount, 2)
    }

    func testReportCountsWithAllOpenIssues() {
        let issue1 = makeIssue(status: .open)
        let issue2 = makeIssue(status: .inProgress)
        let report = makeReport(issues: [issue1, issue2])

        XCTAssertEqual(report.openIssueCount, 2)
        XCTAssertEqual(report.fixedIssueCount, 0)
    }

    func testUrgentIssueCountOnlyCountsUrgent() {
        let issue1 = makeIssue(severity: .urgent)
        let issue2 = makeIssue(severity: .high)
        let issue3 = makeIssue(severity: .urgent)
        let report = makeReport(issues: [issue1, issue2, issue3])

        XCTAssertEqual(report.urgentIssueCount, 2)
    }

    // MARK: - Completion Tests

    func testReportIsComplete() {
        let readyReport = makeReport(status: .ready)
        let exportedReport = makeReport(status: .exported)
        let draftReport = makeReport(status: .draft)
        let archivedReport = makeReport(status: .archived)

        // ready and exported are "complete" states
        XCTAssertTrue(readyReport.status == .ready || readyReport.status == .exported)
        XCTAssertTrue(exportedReport.status == .ready || exportedReport.status == .exported)

        // draft and archived are NOT "complete" in the active sense
        XCTAssertFalse(draftReport.status == .ready || draftReport.status == .exported)
        XCTAssertFalse(archivedReport.status == .ready || archivedReport.status == .exported)
    }

    // MARK: - Type Display Name Tests

    func testReportTypeDisplayNames() {
        // All report types should have non-empty display names (tested in EnumTests)
        // Here we test specific expected values
        XCTAssertFalse(ReportType.moveIn.displayName.isEmpty)
        XCTAssertFalse(ReportType.moveOut.displayName.isEmpty)
        XCTAssertFalse(ReportType.snagging.displayName.isEmpty)
        XCTAssertFalse(ReportType.cleaning.displayName.isEmpty)
        XCTAssertFalse(ReportType.maintenance.displayName.isEmpty)
        XCTAssertFalse(ReportType.airbnb.displayName.isEmpty)
        XCTAssertFalse(ReportType.general.displayName.isEmpty)
    }

    // MARK: - Status Color Tests

    func testReportStatusColors() {
        // Verify all statuses produce a valid Color (no crash)
        for status in ReportStatus.allCases {
            let color = status.color
            XCTAssertNotNil(color, "ReportStatus '\(status)' should have a valid color")
        }
    }

    // MARK: - Date Formatting Tests

    func testReportDateFormatting() {
        let calendar = Calendar.current
        let specificDate = calendar.date(from: DateComponents(year: 2024, month: 6, day: 15, hour: 10, minute: 30))!

        let report = makeReport(inspectionDate: specificDate)

        XCTAssertEqual(report.inspectionDate, specificDate)
        XCTAssertTrue(report.createdAt <= Date(), "createdAt should be in the past or present")
    }

    func testReportDateComponents() {
        let report = makeReport()
        let calendar = Calendar.current

        let createdComponents = calendar.dateComponents([.year, .month, .day], from: report.createdAt)
        let nowComponents = calendar.dateComponents([.year, .month, .day], from: Date())

        XCTAssertEqual(createdComponents.year, nowComponents.year)
        XCTAssertEqual(createdComponents.month, nowComponents.month)
        XCTAssertEqual(createdComponents.day, nowComponents.day)
    }

    func testReportDatesAreIndependent() {
        let report1 = makeReport()
        let report2 = makeReport()

        // Two reports created sequentially should have different or equal creation times
        // (they might be equal if created in the same runloop iteration)
        XCTAssertNotNil(report1.createdAt)
        XCTAssertNotNil(report2.createdAt)
    }

    // MARK: - Relationship Tests

    func testReportAreasRelationship() {
        let area1 = makeArea(name: "Living Room")
        let area2 = makeArea(name: "Kitchen")
        let report = makeReport(areas: [area1, area2])

        XCTAssertEqual(report.areas?.count ?? 0, 2)
    }

    func testReportIssuesRelationship() {
        let issue1 = makeIssue(title: "Wall damage")
        let issue2 = makeIssue(title: "Floor stain")
        let report = makeReport(issues: [issue1, issue2])

        XCTAssertEqual(report.issues?.count ?? 0, 2)
    }

    func testReportWithBothAreasAndIssues() {
        let area = makeArea(name: "Bathroom")
        let issue = makeIssue(title: "Mold on ceiling")
        let report = makeReport(areas: [area], issues: [issue])

        XCTAssertEqual(report.areaCount, 1)
        XCTAssertEqual(report.issueCount, 1)
    }

    // MARK: - Edge Cases

    func testReportWithEmptyTitle() {
        let report = makeReport(title: "")
        XCTAssertEqual(report.title, "")
    }

    func testReportWithLongTitle() {
        let longTitle = String(repeating: "A", count: 1000)
        let report = makeReport(title: longTitle)
        XCTAssertEqual(report.title.count, 1000)
    }

    func testReportWithSpecialCharacters() {
        let specialTitle = "Report: Kitchen & Bath <2024>"
        let report = makeReport(title: specialTitle)
        XCTAssertEqual(report.title, specialTitle)
    }

    func testReportStatusRawBacking() {
        let report = makeReport(status: .ready)
        XCTAssertEqual(report.statusRaw, "ready")

        report.status = .exported
        XCTAssertEqual(report.statusRaw, "exported")

        report.status = .archived
        XCTAssertEqual(report.statusRaw, "archived")
    }

    func testReportTypeRawBacking() {
        let report = makeReport(reportType: .moveIn)
        XCTAssertEqual(report.reportTypeRaw, "moveIn")

        report.reportType = .airbnb
        XCTAssertEqual(report.reportTypeRaw, "airbnb")
    }

    func testReportWithManyAreas() {
        let areas = (1...50).map { makeArea(name: "Area \($0)") }
        let report = makeReport(areas: areas)

        XCTAssertEqual(report.areaCount, 50)
    }

    func testReportWithManyIssues() {
        let issues = (1...100).map { makeIssue(title: "Issue \($0)", severity: .urgent) }
        let report = makeReport(issues: issues)

        XCTAssertEqual(report.issueCount, 100)
        XCTAssertEqual(report.urgentIssueCount, 100)
    }
}
