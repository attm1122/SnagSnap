import XCTest
import SwiftData
@testable import SnagSnap

final class JourneyCompletionTests: XCTestCase {
    func testOrganizeJourneyAreaSavePersistsAndCompletes() throws {
        let context = try makeContext()
        let report = InspectionReport(
            title: "Draft Property Report",
            propertyName: "New Property",
            propertyAddress: "Address to add"
        )
        context.insert(report)

        var didComplete = false
        let viewModel = AddEditAreaViewModel(
            report: report,
            modelContext: context,
            onComplete: { didComplete = true }
        )
        viewModel.name = "Kitchen"
        viewModel.notes = "Check appliances and worktops"

        XCTAssertTrue(viewModel.save())
        XCTAssertTrue(didComplete)
        XCTAssertEqual(report.areaCount, 1)
        XCTAssertEqual(report.areas?.first?.name, "Kitchen")
    }

    func testCaptureJourneyIssueSavePersistsRelationshipsAndCompletes() throws {
        let context = try makeContext()
        let report = InspectionReport(
            title: "Draft Property Report",
            propertyName: "New Property",
            propertyAddress: "Address to add"
        )
        let area = InspectionArea(name: "General")
        context.insert(report)
        context.insert(area)
        area.report = report
        report.areas = [area]

        var didComplete = false
        let viewModel = CreateEditIssueViewModel(
            area: area,
            report: report,
            modelContext: context,
            onComplete: { didComplete = true }
        )
        viewModel.title = "Cracked tile"
        viewModel.notes = "Visible crack near sink"
        viewModel.severity = .high

        XCTAssertTrue(viewModel.save())
        XCTAssertTrue(didComplete)
        XCTAssertEqual(report.issueCount, 1)
        XCTAssertEqual(area.issueCount, 1)
        XCTAssertEqual(report.issues?.first?.area?.id, area.id)
    }

    func testInvalidIssueDoesNotCompleteJourney() throws {
        let context = try makeContext()
        let report = InspectionReport(
            title: "Draft Property Report",
            propertyName: "New Property",
            propertyAddress: "Address to add"
        )
        context.insert(report)

        var didComplete = false
        let viewModel = CreateEditIssueViewModel(
            area: nil,
            report: report,
            modelContext: context,
            onComplete: { didComplete = true }
        )

        XCTAssertFalse(viewModel.save())
        XCTAssertFalse(didComplete)
        XCTAssertTrue(viewModel.showValidationError)
    }

    private func makeContext() throws -> ModelContext {
        let schema = Schema([
            UserProfile.self,
            InspectionReport.self,
            InspectionArea.self,
            InspectionIssue.self,
            IssuePhoto.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        return ModelContext(container)
    }
}
