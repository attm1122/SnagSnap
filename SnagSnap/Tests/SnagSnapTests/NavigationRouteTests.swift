import XCTest
@testable import SnagSnap

final class NavigationRouteTests: XCTestCase {
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
}
