import XCTest
@testable import SnagSnap

final class EntitlementTests: XCTestCase {
    private var manager: EntitlementManager!

    override func setUp() {
        super.setUp()
        manager = EntitlementManager()
        manager.resetForTesting()
    }

    override func tearDown() {
        manager.resetForTesting()
        manager = nil
        super.tearDown()
    }

    func testFreeTierAllowsOneReportPerMonth() throws {
        XCTAssertTrue(manager.canCreateNewReport())
        XCTAssertEqual(manager.remainingFreeReports, 1)

        try manager.attemptCreateReport()

        XCTAssertFalse(manager.canCreateNewReport())
        XCTAssertEqual(manager.remainingFreeReports, 0)
        XCTAssertTrue(manager.hasReachedFreeLimit)
        XCTAssertThrowsError(try manager.validateCanCreateReport()) { error in
            XCTAssertTrue(error is EntitlementError)
        }
    }

    func testFreeTierPDFSettingsIncludeWatermark() {
        let settings = manager.pdfExportSettings(inspectorName: "Inspector", companyName: "SnagSnap")

        XCTAssertTrue(settings.includeWatermark)
        XCTAssertTrue(settings.includeInspectorDetails)
        XCTAssertTrue(settings.includePhotos)
        XCTAssertEqual(settings.inspectorName, "Inspector")
        XCTAssertEqual(settings.companyName, "SnagSnap")
    }

    func testUpgradePromptFlagPersists() {
        XCTAssertFalse(manager.hasUpgradePromptBeenShown)
        manager.markUpgradePromptShown()
        XCTAssertTrue(manager.hasUpgradePromptBeenShown)
    }
}
