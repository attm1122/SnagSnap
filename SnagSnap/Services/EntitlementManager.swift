//
//  EntitlementManager.swift
//  SnagSnap
//
//  Manages feature entitlements and free-tier usage limits.
//

import Foundation
import SwiftData

/// Errors that can occur during entitlement checks.
enum EntitlementError: Error, LocalizedError {
    case freeLimitReached
    case upgradeRequired
    case invalidState

    var errorDescription: String? {
        switch self {
        case .freeLimitReached:
            return "You have reached the monthly limit for free reports. Upgrade to Pro for unlimited reports."
        case .upgradeRequired:
            return "This feature requires a Pro subscription."
        case .invalidState:
            return "The entitlement manager is in an invalid state."
        }
    }
}

/// Manages feature access control based on subscription state and usage limits.
///
/// `EntitlementManager` enforces free-tier limits and provides Pro feature access
/// based on the current subscription state from `StoreKitService`. It tracks
/// monthly report creation counts and resets them on a calendar-month basis.
///
/// ## Free Tier Limits
/// - Maximum **1** inspection report per calendar month
/// - Watermarked PDF exports
/// - Basic features only
///
/// ## Pro Tier Benefits
/// - Unlimited inspection reports
/// - No watermarks on PDF exports
/// - Advanced export options
/// - All premium features
///
/// ## Usage
/// ```swift
/// let manager = EntitlementManager.shared
///
/// if manager.canCreateNewReport() {
///     // Proceed with creating a report
///     manager.incrementReportCount()
/// } else {
///     // Show upgrade prompt
/// }
/// ```
@Observable
class EntitlementManager {

    // MARK: - Shared Instance

    /// The shared singleton instance.
    static let shared = EntitlementManager()

    // MARK: - Constants

    /// Maximum number of free reports allowed per calendar month.
    static let freeMonthlyReportLimit = 1

    /// UserDefaults key for storing the monthly report count.
    private let reportCountKey = "com.snagsnap.entitlement.monthlyReportCount"
    /// UserDefaults key for storing the last reset date.
    private let lastResetKey = "com.snagsnap.entitlement.lastReportResetDate"
    /// UserDefaults key for storing whether the user has ever been shown the upgrade prompt.
    private let upgradePromptShownKey = "com.snagsnap.entitlement.upgradePromptShown"

    // MARK: - Properties

    /// Reference to the StoreKit service for subscription state.
    private let storeKitService = StoreKitService.shared

    /// Number of reports created in the current calendar month.
    private(set) var monthlyReportCount: Int = 0

    /// Date when the monthly count was last reset.
    private(set) var lastReportResetDate: Date?

    // MARK: - Computed Properties

    /// Whether the user has an active Pro subscription.
    var isPro: Bool { storeKitService.isPro }

    /// Number of remaining free reports for the current month.
    var remainingFreeReports: Int {
        if storeKitService.isPro { return Int.max }
        resetMonthlyCountIfNeeded()
        return max(0, Self.freeMonthlyReportLimit - monthlyReportCount)
    }

    /// Whether the user has exceeded their free report limit.
    var hasReachedFreeLimit: Bool {
        if storeKitService.isPro { return false }
        resetMonthlyCountIfNeeded()
        return monthlyReportCount >= Self.freeMonthlyReportLimit
    }

    /// Whether PDF exports should include a watermark.
    var shouldShowWatermark: Bool {
        !storeKitService.isPro
    }

    /// Whether the user should be shown an upgrade prompt.
    var shouldShowUpgradePrompt: Bool {
        !storeKitService.isPro && hasReachedFreeLimit
    }

    // MARK: - Initialization

    /// Creates a new `EntitlementManager` and loads persisted state.
    init() {
        self.monthlyReportCount = UserDefaults.standard.integer(forKey: reportCountKey)
        self.lastReportResetDate = UserDefaults.standard.object(forKey: lastResetKey) as? Date
        resetMonthlyCountIfNeeded()
    }

    // MARK: - Public Methods - Report Creation

    /// Checks whether the user can create a new inspection report.
    ///
    /// Pro users can always create reports. Free users are limited to
    /// `freeMonthlyReportLimit` reports per calendar month.
    ///
    /// - Returns: `true` if a new report can be created.
    func canCreateNewReport() -> Bool {
        if storeKitService.isPro { return true }
        resetMonthlyCountIfNeeded()
        return monthlyReportCount < Self.freeMonthlyReportLimit
    }

    /// Validates that the user can create a new report, throwing if not.
    ///
    /// - Throws: `EntitlementError.freeLimitReached` if the free limit is exceeded.
    func validateCanCreateReport() throws {
        guard canCreateNewReport() else {
            throw EntitlementError.freeLimitReached
        }
    }

    /// Increments the report creation counter.
    ///
    /// Call this after successfully creating a new report. This method
    /// ensures the monthly counter is current before incrementing.
    func incrementReportCount() {
        resetMonthlyCountIfNeeded()
        monthlyReportCount += 1
        UserDefaults.standard.set(monthlyReportCount, forKey: reportCountKey)
    }

    /// Attempts to create a report, incrementing the count if allowed.
    ///
    /// - Returns: `true` if the report count was incremented.
    /// - Throws: `EntitlementError.freeLimitReached` if the user cannot create a report.
    @discardableResult
    func attemptCreateReport() throws -> Bool {
        try validateCanCreateReport()
        incrementReportCount()
        return true
    }

    // MARK: - Public Methods - Feature Access

    /// Checks whether a Pro-only feature is accessible.
    ///
    /// - Returns: `true` if the user has Pro access.
    func canAccessProFeature() -> Bool {
        storeKitService.isPro
    }

    /// Validates Pro feature access, throwing if the user is on the free tier.
    ///
    /// - Throws: `EntitlementError.upgradeRequired` if the user does not have Pro.
    func validateProAccess() throws {
        guard storeKitService.isPro else {
            throw EntitlementError.upgradeRequired
        }
    }

    /// Returns PDF export settings appropriate for the current subscription tier.
    ///
    /// Free users receive settings with the watermark enabled.
    ///
    /// - Returns: `PDFExportSettings` configured for the user's tier.
    func pdfExportSettings(inspectorName: String? = nil, companyName: String? = nil) -> PDFExportSettings {
        var settings = PDFExportSettings()
        settings.includeWatermark = !storeKitService.isPro
        settings.includeInspectorDetails = true
        settings.includePhotos = true
        settings.includeIssueStatuses = true
        settings.inspectorName = inspectorName
        settings.companyName = companyName
        return settings
    }

    // MARK: - Public Methods - Monthly Count Management

    /// Resets the monthly report count if the calendar month has changed.
    ///
    /// Compares the last reset date with the current date. If they differ
    /// by month (or year), the counter is reset to zero.
    func resetMonthlyCountIfNeeded() {
        guard let lastReset = lastReportResetDate else {
            lastReportResetDate = Date()
            monthlyReportCount = 0
            UserDefaults.standard.set(0, forKey: reportCountKey)
            UserDefaults.standard.set(Date(), forKey: lastResetKey)
            return
        }

        let calendar = Calendar.current
        let now = Date()

        if !calendar.isDate(lastReset, equalTo: now, toGranularity: .month) {
            monthlyReportCount = 0
            lastReportResetDate = now
            UserDefaults.standard.set(0, forKey: reportCountKey)
            UserDefaults.standard.set(now, forKey: lastResetKey)
        }
    }

    /// Manually resets the report count for the current month.
    ///
    /// Primarily used for testing or administrative purposes.
    func forceResetMonthlyCount() {
        monthlyReportCount = 0
        lastReportResetDate = Date()
        UserDefaults.standard.set(0, forKey: reportCountKey)
        UserDefaults.standard.set(Date(), forKey: lastResetKey)
    }

    // MARK: - Public Methods - Upgrade Prompt

    /// Marks that the upgrade prompt has been shown to the user.
    func markUpgradePromptShown() {
        UserDefaults.standard.set(true, forKey: upgradePromptShownKey)
    }

    /// Whether the upgrade prompt has ever been shown.
    var hasUpgradePromptBeenShown: Bool {
        UserDefaults.standard.bool(forKey: upgradePromptShownKey)
    }

    // MARK: - Public Methods - Testing

    /// Resets all entitlement state for testing purposes.
    ///
    /// Clears report counts, reset dates, and prompt flags.
    func resetForTesting() {
        monthlyReportCount = 0
        lastReportResetDate = Date()
        UserDefaults.standard.set(0, forKey: reportCountKey)
        UserDefaults.standard.set(Date(), forKey: lastResetKey)
        UserDefaults.standard.set(false, forKey: upgradePromptShownKey)
    }

    /// Simulates a Pro subscription state for testing.
    ///
    /// > Warning: This does not actually purchase a subscription.
    /// > It only affects the local entitlement cache.
    func simulateProForTesting() {
        UserDefaults.standard.set(999, forKey: reportCountKey)
    }

    /// Returns a description of the current entitlement state for debugging.
    var debugDescription: String {
        """
        EntitlementManager:
        - isPro: \(isPro)
        - monthlyReportCount: \(monthlyReportCount)
        - lastReportResetDate: \(lastReportResetDate?.description ?? "nil")
        - remainingFreeReports: \(remainingFreeReports)
        - hasReachedFreeLimit: \(hasReachedFreeLimit)
        """
    }
}
