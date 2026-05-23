import XCTest
@testable import SnagSnap

final class NavigationRouteTests: XCTestCase {
    override func tearDown() {
        AppRouter.shared.resetToRoot()
        super.tearDown()
    }

    func testCreateReportRouteCarriesWorkspaceLaunchAction() {
        let route = Route.createReport(targetTab: .areas, launchAction: .addArea)

        guard case .createReport(let targetTab, let launchAction) = route else {
            return XCTFail("Expected create report route")
        }

        XCTAssertEqual(targetTab, .areas)
        XCTAssertEqual(launchAction, .addArea)
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
