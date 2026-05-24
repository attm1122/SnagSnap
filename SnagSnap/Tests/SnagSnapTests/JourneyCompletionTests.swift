import XCTest
import SwiftData
@testable import SnagSnap

final class JourneyCompletionTests: XCTestCase {
    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
        UserDefaults.standard.removeObject(forKey: "selectedUseCase")
        super.tearDown()
    }

    func testCreateReportDraftTrimsValuesAndBuildsReport() throws {
        var draft = CreateReportDraft()
        draft.title = "  Final Inspection  "
        draft.propertyName = "  Harbour View  "
        draft.propertyAddress = "  12 Water Street  "
        draft.clientName = "  Alex Client  "
        draft.inspectorName = "  Jamie Inspector  "
        draft.generalNotes = "  Confirm access code before arrival.  "
        draft.reportType = .moveOut

        XCTAssertTrue(draft.validate())

        let report = try XCTUnwrap(draft.makeReport())
        XCTAssertEqual(report.title, "Final Inspection")
        XCTAssertEqual(report.propertyName, "Harbour View")
        XCTAssertEqual(report.propertyAddress, "12 Water Street")
        XCTAssertEqual(report.clientName, "Alex Client")
        XCTAssertEqual(report.inspectorName, "Jamie Inspector")
        XCTAssertEqual(report.generalNotes, "Confirm access code before arrival.")
        XCTAssertEqual(report.reportType, .moveOut)
    }

    func testCreateReportDraftRejectsMissingRequiredFields() {
        var draft = CreateReportDraft()
        draft.title = "  "
        draft.propertyName = "Property"
        draft.propertyAddress = "Address"

        XCTAssertFalse(draft.validate())
        XCTAssertTrue(draft.showValidationErrors)
        XCTAssertNil(draft.makeReport())
    }

    func testOnboardingCanCompleteWithoutOptionalBrandingProfile() throws {
        let context = try makeContext()
        let viewModel = OnboardingViewModel()

        XCTAssertTrue(viewModel.canContinueFromUseCases)
        XCTAssertTrue(viewModel.canCompleteOnboarding)

        viewModel.completeOnboarding(context: context)

        let profiles = try context.fetch(FetchDescriptor<UserProfile>())
        XCTAssertTrue(profiles.isEmpty)
        XCTAssertTrue(UserDefaults.standard.bool(forKey: "hasCompletedOnboarding"))
    }

    func testOnboardingPersistsTrimmedBrandingWhenProvided() throws {
        let context = try makeContext()
        let viewModel = OnboardingViewModel()
        viewModel.companyName = "  Premier Property  "
        viewModel.inspectorName = "  Jane Inspector  "
        viewModel.phone = "  +44 7700 900123  "
        viewModel.email = "  jane@example.com  "

        viewModel.completeOnboarding(context: context)

        let profile = try XCTUnwrap(try context.fetch(FetchDescriptor<UserProfile>()).first)
        XCTAssertEqual(profile.companyName, "Premier Property")
        XCTAssertEqual(profile.inspectorName, "Jane Inspector")
        XCTAssertEqual(profile.phone, "+44 7700 900123")
        XCTAssertEqual(profile.email, "jane@example.com")
    }

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

    func testCaptureDraftFactoryCreatesReportAndGeneralArea() throws {
        let context = try makeContext()

        let draft = try CaptureDraftFactory.makeCaptureDraft(context: context)

        XCTAssertEqual(draft.report.title, "Draft Photo Report")
        XCTAssertEqual(draft.report.propertyName, "Property to identify")
        XCTAssertEqual(draft.report.propertyAddress, "Address to add")
        XCTAssertEqual(draft.report.generalNotes, "Started from photo capture. Complete the property details before sharing.")
        XCTAssertEqual(draft.area.name, "General")
        XCTAssertEqual(draft.area.report?.id, draft.report.id)
        XCTAssertEqual(draft.report.areas?.first?.id, draft.area.id)

        let reports = try context.fetch(FetchDescriptor<InspectionReport>())
        let areas = try context.fetch(FetchDescriptor<InspectionArea>())
        XCTAssertEqual(reports.count, 1)
        XCTAssertEqual(areas.count, 1)
    }

    func testCaptureDraftFactoryUsesExistingGeneralAreaBeforeFirstArea() throws {
        let context = try makeContext()
        let report = InspectionReport(
            title: "Existing Report",
            propertyName: "Harbour View",
            propertyAddress: "12 Water Street"
        )
        let kitchen = InspectionArea(name: "Kitchen")
        let general = InspectionArea(name: "General")
        context.insert(report)
        context.insert(kitchen)
        context.insert(general)
        kitchen.report = report
        general.report = report
        report.areas = [kitchen, general]
        try context.save()

        let selectedArea = try CaptureDraftFactory.generalArea(for: report, context: context)

        XCTAssertEqual(selectedArea.id, general.id)
        XCTAssertEqual(report.areas?.count, 2)
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

    func testCancelingNewIssueCleansUpPendingPhotos() throws {
        let context = try makeContext()
        let report = InspectionReport(
            title: "Draft Property Report",
            propertyName: "New Property",
            propertyAddress: "Address to add"
        )
        let area = InspectionArea(name: "General")
        let pendingPhoto = IssuePhoto(
            originalImagePath: "pending-original.jpg",
            thumbnailImagePath: "pending-thumbnail.jpg",
            annotatedImagePath: "pending-annotated.jpg"
        )
        context.insert(report)
        context.insert(area)
        context.insert(pendingPhoto)
        area.report = report
        report.areas = [area]
        try context.save()

        var didComplete = false
        let viewModel = CreateEditIssueViewModel(
            area: area,
            report: report,
            modelContext: context,
            onComplete: { didComplete = true }
        )
        viewModel.pendingPhotos = [pendingPhoto]

        viewModel.cancel()

        XCTAssertTrue(didComplete)
        XCTAssertTrue(viewModel.pendingPhotos.isEmpty)
        let photos = try context.fetch(FetchDescriptor<IssuePhoto>())
        XCTAssertTrue(photos.isEmpty)
    }

    func testDraftReportExposesReadinessGapsBeforeExport() throws {
        let report = InspectionReport(
            title: "Draft Property Report",
            propertyName: "New Property",
            propertyAddress: "Address to add"
        )

        XCTAssertTrue(report.hasPlaceholderDetails)
        XCTAssertFalse(report.isReadyForExport)
        XCTAssertTrue(report.readinessGaps.contains("Add a clear report title"))
        XCTAssertTrue(report.readinessGaps.contains("Add the property name"))
        XCTAssertTrue(report.readinessGaps.contains("Add the property address"))
        XCTAssertTrue(report.readinessGaps.contains("Add at least one area"))
        XCTAssertTrue(report.readinessGaps.contains("Add issues or notes from the inspection"))
    }

    func testCompleteReportHasNoExportReadinessGaps() throws {
        let context = try makeContext()
        let report = InspectionReport(
            title: "15 Oak Avenue - Move In",
            propertyName: "15 Oak Avenue",
            propertyAddress: "15 Oak Avenue, Manchester"
        )
        let area = InspectionArea(name: "Kitchen")
        let issue = InspectionIssue(title: "Cracked tile")

        context.insert(report)
        context.insert(area)
        context.insert(issue)

        area.report = report
        issue.report = report
        issue.area = area
        report.areas = [area]
        report.issues = [issue]
        try context.save()

        XCTAssertFalse(report.hasPlaceholderDetails)
        XCTAssertTrue(report.isReadyForExport)
        XCTAssertTrue(report.readinessGaps.isEmpty)
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
