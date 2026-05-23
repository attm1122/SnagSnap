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

    func testReplaceCurrentHomeRouteKeepsSingleVisibleDestination() {
        let router = AppRouter.shared
        router.resetToRoot()
        let report = InspectionReport(
            title: "Draft Property Report",
            propertyName: "New Property",
            propertyAddress: "Address to add"
        )

        router.navigateToCreateReport()
        router.replaceCurrentHomeRoute(with: .reportWorkspace(report))

        XCTAssertEqual(router.homePath.count, 1)
    }
}
