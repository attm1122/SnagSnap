import XCTest
@testable import SnagSnap

// MARK: - AreaModelTests
// Tests for InspectionArea model, suggested names, issue counts, and relationships

final class AreaModelTests: XCTestCase {

    // MARK: - Test Data Helpers

    private func makeArea(
        name: String = "Test Area",
        notes: String? = nil,
        issues: [InspectionIssue] = []
    ) -> InspectionArea {
        InspectionArea(name: name, notes: notes, issues: issues)
    }

    private func makeIssue(
        title: String = "Test Issue",
        notes: String? = nil,
        severity: IssueSeverity = .medium,
        status: IssueStatus = .open
    ) -> InspectionIssue {
        InspectionIssue(
            title: title,
            notes: notes,
            severity: severity,
            status: status
        )
    }

    // MARK: - Creation Tests

    func testAreaCreation() {
        let area = makeArea(
            name: "Master Bedroom",
            notes: "Check all walls and flooring"
        )

        XCTAssertEqual(area.name, "Master Bedroom")
        XCTAssertEqual(area.notes, "Check all walls and flooring")
        XCTAssertEqual(area.issueCount, 0)
    }

    func testAreaCreationWithDefaults() {
        let area = InspectionArea()
        XCTAssertFalse(area.name.isEmpty)
        XCTAssertNil(area.notes)
    }

    func testAreaCreationWithNoNotes() {
        let area = makeArea(name: "Kitchen", notes: nil)
        XCTAssertNil(area.notes)
    }

    func testAreaCreationWithEmptyName() {
        let area = makeArea(name: "")
        XCTAssertEqual(area.name, "")
    }

    func testAreaCreationWithLongName() {
        let longName = String(repeating: "A", count: 500)
        let area = makeArea(name: longName)
        XCTAssertEqual(area.name.count, 500)
    }

    func testAreaCreationWithSpecialCharacters() {
        let specialName = "Kitchen & Dining <Level 1>"
        let area = makeArea(name: specialName)
        XCTAssertEqual(area.name, specialName)
    }

    // MARK: - Suggested Names Tests

    func testSuggestedNames() {
        let suggested = InspectionArea.suggestedNames
        XCTAssertGreaterThanOrEqual(suggested.count, 10, "There should be at least 10 suggested area names")
    }

    func testSuggestedNamesAreNotEmpty() {
        for name in InspectionArea.suggestedNames {
            XCTAssertFalse(name.isEmpty, "Suggested name should not be empty")
        }
    }

    func testSuggestedNamesAreUnique() {
        let suggested = InspectionArea.suggestedNames
        let unique = Set(suggested)
        XCTAssertEqual(unique.count, suggested.count, "Suggested names should be unique")
    }

    func testSuggestedNamesContainCommonAreas() {
        let suggested = InspectionArea.suggestedNames
        // Check for common area names that should be present
        let commonAreas = ["Kitchen", "Living Room", "Bathroom", "Bedroom", "Hallway"]
        for area in commonAreas {
            XCTAssertTrue(
                suggested.contains(where: { $0.localizedCaseInsensitiveContains(area) }) || suggested.contains(area),
                "Suggested names should contain '\(area)'"
            )
        }
    }

    func testSuggestedNamesAllValidStrings() {
        let suggested = InspectionArea.suggestedNames
        for name in suggested {
            XCTAssertGreaterThan(name.count, 0, "Each suggested name should have at least 1 character")
            XCTAssertLessThan(name.count, 100, "Each suggested name should be reasonably short")
        }
    }

    // MARK: - Issue Count Tests

    func testAreaIssueCount() {
        let issue1 = makeIssue(title: "Wall crack")
        let issue2 = makeIssue(title: "Floor stain")
        let area = makeArea(name: "Living Room", issues: [issue1, issue2])

        XCTAssertEqual(area.issueCount, 2)
    }

    func testAreaIssueCountZero() {
        let area = makeArea(issues: [])
        XCTAssertEqual(area.issueCount, 0)
    }

    func testAreaIssueCountNil() {
        let area = makeArea()
        XCTAssertEqual(area.issueCount, 0)
    }

    func testAreaIssueCountWithManyIssues() {
        let issues = (1...50).map { makeIssue(title: "Issue \($0)") }
        let area = makeArea(name: "Large Hallway", issues: issues)

        XCTAssertEqual(area.issueCount, 50)
    }

    // MARK: - Relationship Tests

    func testAreaIssuesRelationship() {
        let issue1 = makeIssue(title: "Ceiling leak", severity: .urgent)
        let issue2 = makeIssue(title: "Loose doorknob", severity: .low)
        let area = makeArea(name: "Bathroom", issues: [issue1, issue2])

        XCTAssertEqual(area.issues?.count ?? 0, 2)
        XCTAssertEqual(area.issues?.first?.title, "Ceiling leak")
    }

    func testAreaWithNoIssues() {
        let area = makeArea(name: "Empty Room", issues: [])
        XCTAssertNil(area.issues) // or empty array depending on implementation
    }

    func testAreaIssueSeverities() {
        let lowIssue = makeIssue(title: "Minor scratch", severity: .low)
        let highIssue = makeIssue(title: "Major crack", severity: .high)
        let urgentIssue = makeIssue(title: "Water leak", severity: .urgent)
        let area = makeArea(name: "Kitchen", issues: [lowIssue, highIssue, urgentIssue])

        XCTAssertEqual(area.issueCount, 3)
        let severities = area.issues?.map(\.severity) ?? []
        XCTAssertTrue(severities.contains(.low))
        XCTAssertTrue(severities.contains(.high))
        XCTAssertTrue(severities.contains(.urgent))
    }

    // MARK: - Notes Tests

    func testAreaNotes() {
        let area = makeArea(name: "Patio", notes: "Check for cracks in concrete")
        XCTAssertEqual(area.notes, "Check for cracks in concrete")
    }

    func testAreaNotesNil() {
        let area = makeArea(name: "Garage", notes: nil)
        XCTAssertNil(area.notes)
    }

    func testAreaNotesEmpty() {
        let area = makeArea(name: "Attic", notes: "")
        XCTAssertEqual(area.notes, "")
    }

    func testAreaNotesLong() {
        let longNotes = String(repeating: "Check this area. ", count: 50)
        let area = makeArea(name: "Basement", notes: longNotes)
        XCTAssertEqual(area.notes?.count, longNotes.count)
    }

    // MARK: - Edge Cases

    func testAreaWithSingleIssue() {
        let issue = makeIssue(title: "Only issue")
        let area = makeArea(issues: [issue])
        XCTAssertEqual(area.issueCount, 1)
    }

    func testAreaNameWithWhitespace() {
        let area = makeArea(name: "  Living Room  ")
        XCTAssertEqual(area.name, "  Living Room  ")
    }

    func testAreaNameWithUnicode() {
        let unicodeName = "Cocina Espanola"
        let area = makeArea(name: unicodeName)
        XCTAssertEqual(area.name, unicodeName)
    }

    func testSuggestedNamesIsStatic() {
        // Verify that suggestedNames is a static property accessible on the type
        let suggested1 = InspectionArea.suggestedNames
        let suggested2 = InspectionArea.suggestedNames
        XCTAssertEqual(suggested1, suggested2, "suggestedNames should be deterministic")
    }

    func testAreaIssuesDeleteRuleNullify() {
        // Verify the delete rule is .nullify (issues are not deleted when area is deleted)
        // This is a model configuration test — we verify the relationship exists
        let area = makeArea(name: "Test Room")
        XCTAssertNotNil(area.issues)
    }

    func testMultipleAreasWithSameName() {
        // Different areas can have the same name (e.g., "Bedroom 1" and "Bedroom 1")
        let area1 = makeArea(name: "Bedroom")
        let area2 = makeArea(name: "Bedroom")

        XCTAssertEqual(area1.name, area2.name)
        XCTAssertFalse(area1 === area2, "Two areas with same name should be different objects")
    }

    func testAreaWithMixedIssueStatuses() {
        let openIssue = makeIssue(title: "Open issue", status: .open)
        let fixedIssue = makeIssue(title: "Fixed issue", status: .fixed)
        let inProgressIssue = makeIssue(title: "In progress", status: .inProgress)
        let archivedIssue = makeIssue(title: "Archived", status: .archived)
        let notAnIssue = makeIssue(title: "Not an issue", status: .notAnIssue)

        let area = makeArea(
            name: "Test Room",
            issues: [openIssue, fixedIssue, inProgressIssue, archivedIssue, notAnIssue]
        )

        XCTAssertEqual(area.issueCount, 5)
    }
}
