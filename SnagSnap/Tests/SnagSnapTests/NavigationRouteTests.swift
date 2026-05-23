import XCTest
@testable import SnagSnap

final class NavigationRouteTests: XCTestCase {
    override func tearDown() {
        AppRouter.shared.resetToRoot()
        super.tearDown()
    }

    func testCreateReportRouteCarriesWorkspaceLaunchAction() {
        let route = Route.createReport(targetTab: .issues, launchAction: .startCapture)

        guard case .createReport(let targetTab, let launchAction) = route else {
            return XCTFail("Expected create report route")
        }

        XCTAssertEqual(targetTab, .issues)
        XCTAssertEqual(launchAction, .startCapture)
    }

    func testReportWorkspaceRouteCarriesInitialTabAndLaunchAction() {
        let report = InspectionReport(
            title: "Draft Property Report",
            propertyName: "New Property",
            propertyAddress: "Address to add"
        )

        let route = Route.reportWorkspace(report, initialTab: .issues, launchAction: .addIssue)

        guard case .reportWorkspace(let reportID, let initialTab, let launchAction) = route else {
            return XCTFail("Expected report workspace route")
        }

        XCTAssertEqual(reportID, report.id)
        XCTAssertEqual(initialTab, .issues)
        XCTAssertEqual(launchAction, .addIssue)
    }

    func testCreateReportNavigationUpdatesHomePath() {
        let router = AppRouter.shared
        router.resetToRoot()

        router.navigateToCreateReport()

        XCTAssertEqual(router.homePath.count, 1)
    }

    func testIssueEditorRouteCarriesStartWithCameraFlag() {
        let report = InspectionReport(
            title: "Draft Photo Report",
            propertyName: "Property to identify",
            propertyAddress: "Address to add"
        )
        let area = InspectionArea(name: "General")

        let route = Route.issueEditor(
            issue: nil,
            area: area,
            report: report,
            startWithCamera: true
        )

        guard case .issueEditor(let issueID, let areaID, let reportID, let startWithCamera) = route else {
            return XCTFail("Expected issue editor route")
        }

        XCTAssertNil(issueID)
        XCTAssertEqual(areaID, area.id)
        XCTAssertEqual(reportID, report.id)
        XCTAssertTrue(startWithCamera)
    }

    func testCompleteCreateReportTransitionsThroughRootBeforeWorkspace() {
        let router = AppRouter.shared
        router.resetToRoot()
        let report = InspectionReport(
            title: "Draft Property Report",
            propertyName: "New Property",
            propertyAddress: "Address to add"
        )

        router.navigateToCreateReport()
        router.completeCreateReport(report)

        XCTAssertTrue(router.homePath.isEmpty)
    }

    func testCompleteCreateReportPushesWorkspaceOnNextRunLoop() {
        let router = AppRouter.shared
        router.resetToRoot()
        let report = InspectionReport(
            title: "Draft Property Report",
            propertyName: "New Property",
            propertyAddress: "Address to add"
        )
        let expectation = expectation(description: "Workspace route is pushed")

        router.navigateToCreateReport()
        router.completeCreateReport(report, targetTab: .areas, launchAction: .addArea)

        DispatchQueue.main.async {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(router.homePath.count, 1)
        guard case .reportWorkspace(let reportID, let initialTab, let launchAction) = router.homePath.first else {
            return XCTFail("Expected report workspace route")
        }
        XCTAssertEqual(reportID, report.id)
        XCTAssertEqual(initialTab, .areas)
        XCTAssertEqual(launchAction, .addArea)
    }
}
