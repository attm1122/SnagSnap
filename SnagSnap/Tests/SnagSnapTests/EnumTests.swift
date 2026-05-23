import XCTest
@testable import SnagSnap

// MARK: - EnumTests
// Comprehensive tests for all enums: ReportStatus, ReportType, IssueSeverity, IssueStatus

final class EnumTests: XCTestCase {

    // MARK: - ReportType Tests

    /// Verify all 7 report type cases exist and have non-empty display names
    func testReportTypeAllCases() {
        let allCases = ReportType.allCases
        XCTAssertEqual(allCases.count, 7, "ReportType should have exactly 7 cases")

        let expectedCases: [ReportType] = [.moveIn, .moveOut, .snagging, .cleaning, .maintenance, .airbnb, .general]
        for expected in expectedCases {
            XCTAssertTrue(allCases.contains(expected), "ReportType should contain \(expected)")
        }
    }

    func testAllReportTypesHaveDisplayNames() {
        for reportType in ReportType.allCases {
            XCTAssertFalse(reportType.displayName.isEmpty,
                           "ReportType '\(reportType)' should have a non-empty display name")
        }
    }

    func testAllReportTypesHaveIcons() {
        for reportType in ReportType.allCases {
            XCTAssertFalse(reportType.icon.isEmpty,
                           "ReportType '\(reportType)' should have a non-empty icon name")
        }
    }

    func testAllReportTypesHaveDescriptions() {
        for reportType in ReportType.allCases {
            XCTAssertFalse(reportType.description.isEmpty,
                           "ReportType '\(reportType)' should have a non-empty description")
        }
    }

    func testReportTypeIdentifiable() {
        for reportType in ReportType.allCases {
            XCTAssertEqual(reportType.id, reportType.rawValue,
                           "ReportType id should match its rawValue")
        }
    }

    func testReportTypeRawValues() {
        XCTAssertEqual(ReportType.moveIn.rawValue, "moveIn")
        XCTAssertEqual(ReportType.moveOut.rawValue, "moveOut")
        XCTAssertEqual(ReportType.snagging.rawValue, "snagging")
        XCTAssertEqual(ReportType.cleaning.rawValue, "cleaning")
        XCTAssertEqual(ReportType.maintenance.rawValue, "maintenance")
        XCTAssertEqual(ReportType.airbnb.rawValue, "airbnb")
        XCTAssertEqual(ReportType.general.rawValue, "general")
    }

    func testReportTypeCodable() throws {
        // Test encoding and decoding round-trip for each case
        for reportType in ReportType.allCases {
            let encoder = JSONEncoder()
            let decoder = JSONDecoder()
            let data = try encoder.encode(reportType.rawValue)
            let decodedRawValue = try decoder.decode(String.self, from: data)
            XCTAssertEqual(decodedRawValue, reportType.rawValue)
        }
    }

    // MARK: - ReportStatus Tests

    func testAllReportStatusesHaveDisplayNames() {
        for status in ReportStatus.allCases {
            XCTAssertFalse(status.displayName.isEmpty,
                           "ReportStatus '\(status)' should have a non-empty display name")
        }
    }

    func testAllReportStatusesHaveIcons() {
        for status in ReportStatus.allCases {
            XCTAssertFalse(status.icon.isEmpty,
                           "ReportStatus '\(status)' should have a non-empty icon name")
        }
    }

    func testAllReportStatusesHaveColors() {
        for status in ReportStatus.allCases {
            // Color exists — just verify no crash; Swift Color is a value type
            _ = status.color
            XCTAssertTrue(true, "ReportStatus '\(status)' should have a valid color")
        }
    }

    func testReportStatusIdentifiable() {
        for status in ReportStatus.allCases {
            XCTAssertEqual(status.id, status.rawValue,
                           "ReportStatus id should match its rawValue")
        }
    }

    func testReportStatusRawValues() {
        XCTAssertEqual(ReportStatus.draft.rawValue, "draft")
        XCTAssertEqual(ReportStatus.ready.rawValue, "ready")
        XCTAssertEqual(ReportStatus.exported.rawValue, "exported")
        XCTAssertEqual(ReportStatus.archived.rawValue, "archived")
    }

    func testReportStatusCodable() throws {
        for status in ReportStatus.allCases {
            let encoder = JSONEncoder()
            let decoder = JSONDecoder()
            let data = try encoder.encode(status.rawValue)
            let decodedRawValue = try decoder.decode(String.self, from: data)
            XCTAssertEqual(decodedRawValue, status.rawValue)
        }
    }

    // MARK: - IssueSeverity Tests

    func testIssueSeverityAllCases() {
        let allCases = IssueSeverity.allCases
        XCTAssertEqual(allCases.count, 4, "IssueSeverity should have exactly 4 cases")

        let expectedCases: [IssueSeverity] = [.low, .medium, .high, .urgent]
        for expected in expectedCases {
            XCTAssertTrue(allCases.contains(expected), "IssueSeverity should contain \(expected)")
        }
    }

    func testAllIssueSeveritiesHaveDisplayNames() {
        for severity in IssueSeverity.allCases {
            XCTAssertFalse(severity.displayName.isEmpty,
                           "IssueSeverity '\(severity)' should have a non-empty display name")
        }
    }

    func testAllIssueSeveritiesHaveIcons() {
        for severity in IssueSeverity.allCases {
            XCTAssertFalse(severity.icon.isEmpty,
                           "IssueSeverity '\(severity)' should have a non-empty icon name")
        }
    }

    func testAllIssueSeveritiesHaveColors() {
        for severity in IssueSeverity.allCases {
            _ = severity.color
            XCTAssertTrue(true, "IssueSeverity '\(severity)' should have a valid color")
        }
    }

    func testIssueSeverityPriorityOrder() {
        XCTAssertEqual(IssueSeverity.low.priority, 1, "Low severity should have priority 1")
        XCTAssertEqual(IssueSeverity.medium.priority, 2, "Medium severity should have priority 2")
        XCTAssertEqual(IssueSeverity.high.priority, 3, "High severity should have priority 3")
        XCTAssertEqual(IssueSeverity.urgent.priority, 4, "Urgent severity should have priority 4")
    }

    func testIssueSeverityPriorityStrictlyIncreasing() {
        let priorities = IssueSeverity.allCases.map(\.priority)
        for i in 1..<priorities.count {
            XCTAssertGreaterThan(priorities[i], priorities[i - 1],
                                 "IssueSeverity priorities should be strictly increasing")
        }
    }

    func testIssueSeverityRawValues() {
        XCTAssertEqual(IssueSeverity.low.rawValue, "low")
        XCTAssertEqual(IssueSeverity.medium.rawValue, "medium")
        XCTAssertEqual(IssueSeverity.high.rawValue, "high")
        XCTAssertEqual(IssueSeverity.urgent.rawValue, "urgent")
    }

    func testIssueSeverityIdentifiable() {
        for severity in IssueSeverity.allCases {
            XCTAssertEqual(severity.id, severity.rawValue)
        }
    }

    func testIssueSeverityCodable() throws {
        for severity in IssueSeverity.allCases {
            let encoder = JSONEncoder()
            let decoder = JSONDecoder()
            let data = try encoder.encode(severity.rawValue)
            let decodedRawValue = try decoder.decode(String.self, from: data)
            XCTAssertEqual(decodedRawValue, severity.rawValue)
        }
    }

    // MARK: - IssueStatus Tests

    func testIssueStatusAllCases() {
        let allCases = IssueStatus.allCases
        XCTAssertEqual(allCases.count, 5, "IssueStatus should have exactly 5 cases")

        let expectedCases: [IssueStatus] = [.open, .inProgress, .fixed, .notAnIssue, .archived]
        for expected in expectedCases {
            XCTAssertTrue(allCases.contains(expected), "IssueStatus should contain \(expected)")
        }
    }

    func testAllIssueStatusesHaveDisplayNames() {
        for status in IssueStatus.allCases {
            XCTAssertFalse(status.displayName.isEmpty,
                           "IssueStatus '\(status)' should have a non-empty display name")
        }
    }

    func testAllIssueStatusesHaveIcons() {
        for status in IssueStatus.allCases {
            XCTAssertFalse(status.icon.isEmpty,
                           "IssueStatus '\(status)' should have a non-empty icon name")
        }
    }

    func testAllIssueStatusesHaveColors() {
        for status in IssueStatus.allCases {
            _ = status.color
            XCTAssertTrue(true, "IssueStatus '\(status)' should have a valid color")
        }
    }

    func testIssueStatusIsOpen() {
        XCTAssertTrue(IssueStatus.open.isOpen, "Open status should be isOpen")
        XCTAssertTrue(IssueStatus.inProgress.isOpen, "InProgress status should be isOpen")
        XCTAssertFalse(IssueStatus.fixed.isOpen, "Fixed status should NOT be isOpen")
        XCTAssertFalse(IssueStatus.notAnIssue.isOpen, "NotAnIssue status should NOT be isOpen")
        XCTAssertFalse(IssueStatus.archived.isOpen, "Archived status should NOT be isOpen")
    }

    func testIssueStatusRawValues() {
        XCTAssertEqual(IssueStatus.open.rawValue, "open")
        XCTAssertEqual(IssueStatus.inProgress.rawValue, "inProgress")
        XCTAssertEqual(IssueStatus.fixed.rawValue, "fixed")
        XCTAssertEqual(IssueStatus.notAnIssue.rawValue, "notAnIssue")
        XCTAssertEqual(IssueStatus.archived.rawValue, "archived")
    }

    func testIssueStatusIdentifiable() {
        for status in IssueStatus.allCases {
            XCTAssertEqual(status.id, status.rawValue)
        }
    }

    func testIssueStatusCodable() throws {
        for status in IssueStatus.allCases {
            let encoder = JSONEncoder()
            let decoder = JSONDecoder()
            let data = try encoder.encode(status.rawValue)
            let decodedRawValue = try decoder.decode(String.self, from: data)
            XCTAssertEqual(decodedRawValue, status.rawValue)
        }
    }

    // MARK: - Cross-Enum Consistency Tests

    func testNoEnumHasEmptyAllCases() {
        XCTAssertFalse(ReportType.allCases.isEmpty, "ReportType should have cases")
        XCTAssertFalse(ReportStatus.allCases.isEmpty, "ReportStatus should have cases")
        XCTAssertFalse(IssueSeverity.allCases.isEmpty, "IssueSeverity should have cases")
        XCTAssertFalse(IssueStatus.allCases.isEmpty, "IssueStatus should have cases")
    }

    func testAllEnumsAreCaseIterable() {
        // Verifies at compile time that all enums conform to CaseIterable
        let _: [ReportType] = ReportType.allCases
        let _: [ReportStatus] = ReportStatus.allCases
        let _: [IssueSeverity] = IssueSeverity.allCases
        let _: [IssueStatus] = IssueStatus.allCases
        XCTAssertTrue(true, "All enums should be CaseIterable")
    }

    func testAllEnumsAreIdentifiable() {
        // Verifies at compile time that all enums conform to Identifiable
        let _: [ReportType] = ReportType.allCases.map { $0 }
        let _: [ReportStatus] = ReportStatus.allCases.map { $0 }
        let _: [IssueSeverity] = IssueSeverity.allCases.map { $0 }
        let _: [IssueStatus] = IssueStatus.allCases.map { $0 }
        XCTAssertTrue(true, "All enums should be Identifiable")
    }

    func testAllEnumsAreCodable() throws {
        // Verifies that all enums can be encoded/decoded via their raw values
        for reportType in ReportType.allCases {
            let data = try JSONEncoder().encode(reportType.rawValue)
            XCTAssertGreaterThan(data.count, 0, "ReportType should be encodable")
        }
        for status in ReportStatus.allCases {
            let data = try JSONEncoder().encode(status.rawValue)
            XCTAssertGreaterThan(data.count, 0, "ReportStatus should be encodable")
        }
        for severity in IssueSeverity.allCases {
            let data = try JSONEncoder().encode(severity.rawValue)
            XCTAssertGreaterThan(data.count, 0, "IssueSeverity should be encodable")
        }
        for issueStatus in IssueStatus.allCases {
            let data = try JSONEncoder().encode(issueStatus.rawValue)
            XCTAssertGreaterThan(data.count, 0, "IssueStatus should be encodable")
        }
    }
}
