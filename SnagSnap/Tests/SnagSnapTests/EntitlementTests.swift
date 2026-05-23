import XCTest
@testable import SnagSnap

// MARK: - EntitlementTests
// Tests for EntitlementManager: free plan limits, pro access, monthly reset, and edge cases

final class EntitlementTests: XCTestCase {

    var entitlementManager: EntitlementManager!

    // MARK: - Setup / Teardown

    override func setUp() {
        super.setUp()
        entitlementManager = EntitlementManager.shared
        entitlementManager.resetForTesting()
    }

    override func tearDown() {
        entitlementManager.resetForTesting()
        entitlementManager = nil
        super.tearDown()
    }

    // MARK: - Free Plan Limit Tests

    func testFreePlanLimit() {
        // Free user should be able to create 1 report
        XCTAssertTrue(entitlementManager.canCreateNewReport(),
                      "Free user should be able to create first report")

        entitlementManager.incrementReportCount()
        // After creating 1 report, should still show 0 remaining
        XCTAssertEqual(entitlementManager.remainingFreeReports, 0,
                       "After 1 report, remaining should be 0")
    }

    func testFreePlanCanCreateExactlyOneReport() {
        // With free plan, can create exactly 1 report
        XCTAssertTrue(entitlementManager.canCreateNewReport(),
                      "Should be able to create first report")

        entitlementManager.incrementReportCount()

        // FreeMonthlyReportLimit is 1
        XCTAssertEqual(EntitlementManager.freeMonthlyReportLimit, 1,
                       "Free monthly report limit should be 1")
    }

    func testFreePlanBlocked() {
        // Create first report
        entitlementManager.incrementReportCount()

        // Should be blocked from creating more
        XCTAssertFalse(entitlementManager.canCreateNewReport(),
                       "Free user should be blocked after reaching limit")
    }

    func testFreePlanBlockedAfterMultipleIncrements() {
        // Simulate creating multiple reports
        entitlementManager.incrementReportCount()
        entitlementManager.incrementReportCount()
        entitlementManager.incrementReportCount()

        XCTAssertFalse(entitlementManager.canCreateNewReport(),
                       "Should be blocked after multiple increments")
        XCTAssertEqual(entitlementManager.remainingFreeReports, 0,
                       "Remaining should be 0 or negative when over limit")
    }

    // MARK: - Remaining Free Reports Tests

    func testRemainingFreeReports() {
        // Initially should have 1 remaining
        XCTAssertEqual(entitlementManager.remainingFreeReports, 1,
                       "Should start with 1 free report")

        // After using one
        entitlementManager.incrementReportCount()
        XCTAssertEqual(entitlementManager.remainingFreeReports, 0,
                       "Should have 0 remaining after using free report")
    }

    func testRemainingFreeReportsDecreases() {
        let initialRemaining = entitlementManager.remainingFreeReports
        XCTAssertGreaterThanOrEqual(initialRemaining, 0)

        if entitlementManager.canCreateNewReport() {
            entitlementManager.incrementReportCount()
            XCTAssertLessThan(entitlementManager.remainingFreeReports, initialRemaining + 1)
        }
    }

    func testRemainingFreeReportsNeverNegative() {
        // Increment many times
        for _ in 0..<10 {
            entitlementManager.incrementReportCount()
        }

        // remainingFreeReports should be 0 (or clamped), never negative
        XCTAssertGreaterThanOrEqual(entitlementManager.remainingFreeReports, 0,
                                    "remainingFreeReports should never be negative")
    }

    // MARK: - Pro Plan Tests

    func testProUnlimited() {
        // Enable pro mode
        entitlementManager.isPro = true

        // Should be able to create many reports
        for i in 0..<100 {
            XCTAssertTrue(entitlementManager.canCreateNewReport(),
                          "Pro user should be able to create report #\(i + 1)")
            entitlementManager.incrementReportCount()
        }
    }

    func testProCanCreateAfterFreeLimit() {
        // Use up the free limit first
        entitlementManager.incrementReportCount()

        // Without pro, blocked
        XCTAssertFalse(entitlementManager.canCreateNewReport())

        // Upgrade to pro
        entitlementManager.isPro = true

        // Now should be able to create
        XCTAssertTrue(entitlementManager.canCreateNewReport(),
                      "Pro user should bypass free limit")
    }

    func testProRemainingReportsIsMax() {
        entitlementManager.isPro = true

        // Pro users should effectively have unlimited/max remaining
        XCTAssertEqual(entitlementManager.remainingFreeReports, Int.max,
                       "Pro users should have Int.max remaining free reports")
    }

    func testProToggleOffRevertsToFreeLimit() {
        // Start pro
        entitlementManager.isPro = true
        XCTAssertTrue(entitlementManager.canCreateNewReport())

        // Use a report
        entitlementManager.incrementReportCount()
        entitlementManager.incrementReportCount()
        entitlementManager.incrementReportCount()

        // Downgrade
        entitlementManager.isPro = false

        // Should be at free limit (blocked)
        XCTAssertFalse(entitlementManager.canCreateNewReport(),
                       "Downgraded user should be blocked if over free limit")
    }

    // MARK: - Monthly Reset Tests

    func testMonthlyReset() {
        // Use up the free report
        entitlementManager.incrementReportCount()
        XCTAssertFalse(entitlementManager.canCreateNewReport())
        XCTAssertEqual(entitlementManager.remainingFreeReports, 0)

        // Simulate month change by calling reset
        entitlementManager.resetMonthlyCountIfNeeded()

        // After reset, should be able to create again
        XCTAssertTrue(entitlementManager.canCreateNewReport(),
                      "Should be able to create report after monthly reset")
        XCTAssertEqual(entitlementManager.remainingFreeReports, 1,
                       "Should have 1 remaining after monthly reset")
    }

    func testMonthlyResetPreservesProStatus() {
        entitlementManager.isPro = true
        entitlementManager.incrementReportCount()

        entitlementManager.resetMonthlyCountIfNeeded()

        XCTAssertTrue(entitlementManager.isPro, "Pro status should persist across monthly resets")
    }

    func testMonthlyResetWithNoUsage() {
        // Reset without using any reports
        XCTAssertEqual(entitlementManager.remainingFreeReports, 1)
        entitlementManager.resetMonthlyCountIfNeeded()
        XCTAssertEqual(entitlementManager.remainingFreeReports, 1,
                       "Reset with no usage should still show 1 remaining")
    }

    func testMonthlyResetMultipleTimes() {
        // Use and reset multiple cycles
        for cycle in 0..<5 {
            entitlementManager.incrementReportCount()
            XCTAssertFalse(entitlementManager.canCreateNewReport(),
                           "Should be blocked in cycle \(cycle)")

            entitlementManager.resetMonthlyCountIfNeeded()
            XCTAssertTrue(entitlementManager.canCreateNewReport(),
                          "Should be able to create after reset in cycle \(cycle)")
        }
    }

    // MARK: - Reset for Testing Tests

    func testResetForTestingClearsCount() {
        // Use some reports
        entitlementManager.incrementReportCount()
        entitlementManager.incrementReportCount()

        // Reset
        entitlementManager.resetForTesting()

        // Should be back to initial state
        XCTAssertTrue(entitlementManager.canCreateNewReport())
        XCTAssertEqual(entitlementManager.remainingFreeReports, 1)
    }

    func testResetForTestingPreservesProIfNeeded() {
        entitlementManager.isPro = true
        entitlementManager.incrementReportCount()

        entitlementManager.resetForTesting()

        // isPro may or may not be reset — test behavior
        if entitlementManager.isPro {
            XCTAssertTrue(entitlementManager.canCreateNewReport())
        } else {
            // If pro was reset, should have free report available
            XCTAssertTrue(entitlementManager.canCreateNewReport())
        }
    }

    // MARK: - Singleton Tests

    func testSharedInstance() {
        let shared1 = EntitlementManager.shared
        let shared2 = EntitlementManager.shared
        XCTAssertTrue(shared1 === shared2, "shared should return the same instance")
    }

    func testSharedInstanceStatePersists() {
        let manager = EntitlementManager.shared
        manager.resetForTesting()

        XCTAssertTrue(manager.canCreateNewReport())
        manager.incrementReportCount()

        // Same instance should reflect the change
        XCTAssertFalse(EntitlementManager.shared.canCreateNewReport())

        // Clean up
        manager.resetForTesting()
    }

    // MARK: - Free Monthly Report Limit Constant

    func testFreeMonthlyReportLimitValue() {
        XCTAssertEqual(EntitlementManager.freeMonthlyReportLimit, 1,
                       "Free monthly report limit should be exactly 1")
    }

    func testFreeMonthlyReportLimitIsPositive() {
        XCTAssertGreaterThan(EntitlementManager.freeMonthlyReportLimit, 0,
                             "Free monthly report limit should be positive")
    }

    // MARK: - Edge Cases

    func testCanCreateNewReportWithZeroRemaining() {
        // Use the free report
        entitlementManager.incrementReportCount()

        // remainingFreeReports should be 0
        XCTAssertEqual(entitlementManager.remainingFreeReports, 0)

        // Should not be able to create
        XCTAssertFalse(entitlementManager.canCreateNewReport())
    }

    func testIncrementReportCountBeyondLimit() {
        // Increment many times past the limit
        for _ in 0..<50 {
            entitlementManager.incrementReportCount()
        }

        // Should still be blocked
        XCTAssertFalse(entitlementManager.canCreateNewReport())
    }

    func testProUserAlwaysHasUnlimitedAccess() {
        entitlementManager.isPro = true

        // Even after "unlimited" increments, should still be able to create
        for _ in 0..<1000 {
            XCTAssertTrue(entitlementManager.canCreateNewReport())
            entitlementManager.incrementReportCount()
        }

        XCTAssertTrue(entitlementManager.canCreateNewReport())
    }

    func testIsProDefaultsToFalse() {
        // After reset, isPro should be false by default
        entitlementManager.resetForTesting()
        XCTAssertFalse(entitlementManager.isPro, "isPro should default to false")
    }

    func testCombinedProAndReset() {
        // Use free report
        entitlementManager.incrementReportCount()
        XCTAssertFalse(entitlementManager.canCreateNewReport())

        // Upgrade to pro
        entitlementManager.isPro = true
        XCTAssertTrue(entitlementManager.canCreateNewReport())

        // Use many reports
        for _ in 0..<50 {
            entitlementManager.incrementReportCount()
        }
        XCTAssertTrue(entitlementManager.canCreateNewReport())

        // Downgrade
        entitlementManager.isPro = false

        // Reset monthly count
        entitlementManager.resetMonthlyCountIfNeeded()

        // Should be back to 1 free report
        XCTAssertTrue(entitlementManager.canCreateNewReport())
        entitlementManager.incrementReportCount()
        XCTAssertFalse(entitlementManager.canCreateNewReport())
    }

    func testFreePlanBlockedAfterExactlyOne() {
        // Exact boundary test: create exactly 1 report
        XCTAssertTrue(entitlementManager.canCreateNewReport())

        entitlementManager.incrementReportCount()

        // Should be blocked now
        XCTAssertFalse(entitlementManager.canCreateNewReport())
        XCTAssertEqual(entitlementManager.remainingFreeReports, 0)
    }

    func testRemainingReportsWhenPro() {
        entitlementManager.isPro = true
        XCTAssertEqual(entitlementManager.remainingFreeReports, Int.max)

        // Even after some usage
        entitlementManager.incrementReportCount()
        entitlementManager.incrementReportCount()
        XCTAssertEqual(entitlementManager.remainingFreeReports, Int.max)
    }

    func testResetMonthlyCountIfNeededWhenSameMonth() {
        entitlementManager.resetForTesting()

        // Reset twice in "same month" should still work
        entitlementManager.resetMonthlyCountIfNeeded()
        XCTAssertTrue(entitlementManager.canCreateNewReport())

        entitlementManager.resetMonthlyCountIfNeeded()
        XCTAssertTrue(entitlementManager.canCreateNewReport())
    }
}
