//
//  ReportRepository.swift
//  SnagSnap
//
//  Repository pattern for SwiftData operations on inspection reports.
//

import Foundation
import SwiftData
import SwiftUI

/// Errors that can occur during report repository operations.
enum ReportRepositoryError: Error, LocalizedError {
    case saveFailed(underlying: Error)
    case deleteFailed(underlying: Error)
    case fetchFailed(underlying: Error)
    case reportNotFound
    case invalidData
    case contextNotAvailable

    var errorDescription: String? {
        switch self {
        case .saveFailed(let error):
            return "Failed to save the report: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete the report: \(error.localizedDescription)"
        case .fetchFailed(let error):
            return "Failed to fetch reports: \(error.localizedDescription)"
        case .reportNotFound:
            return "The requested report could not be found."
        case .invalidData:
            return "The report data is invalid or incomplete."
        case .contextNotAvailable:
            return "The data storage context is not available."
        }
    }
}

/// Sort order options for report queries.
enum ReportSortOrder {
    case newestFirst
    case oldestFirst
    case titleAscending
    case titleDescending
    case propertyNameAscending
}

/// Filter criteria for report queries.
struct ReportFilterCriteria {
    var searchText: String?
    var status: ReportStatus?
    var reportType: ReportType?
    var dateRange: ClosedRange<Date>?

    /// Whether any filter is active.
    var isActive: Bool {
        searchText?.isEmpty == false ||
        status != nil ||
        reportType != nil ||
        dateRange != nil
    }

    /// An empty criteria set with no filters applied.
    static var none: ReportFilterCriteria { ReportFilterCriteria() }
}

/// Repository for `InspectionReport` CRUD operations using SwiftData.
///
/// `ReportRepository` provides a clean, async interface for creating, reading,
/// updating, and deleting inspection reports. It encapsulates all SwiftData
/// model context operations and provides search, filter, and sort capabilities.
///
/// ## Usage
/// ```swift
/// @State private var repository = ReportRepository()
///
/// // Create a report
/// let report = InspectionReport(title: "New Report", ...)
/// try await repository.insert(report)
///
/// // Fetch all reports
/// let reports = try await repository.fetchAll()
///
/// // Search
/// let results = try await repository.search(query: "kitchen")
/// ```
@Observable
class ReportRepository {

    // MARK: - Properties

    /// The SwiftData model context for database operations.
    private var modelContext: ModelContext?

    /// The file storage service for cleaning up associated files.
    private let fileStorage: FileStorageService

    /// The entitlement manager for enforcing creation limits.
    private let entitlementManager: EntitlementManager

    // MARK: - Initialization

    /// Creates a new `ReportRepository`.
    ///
    /// - Parameters:
    ///   - fileStorage: The `FileStorageService` for file operations. Defaults to shared.
    ///   - entitlementManager: The `EntitlementManager` for limit enforcement. Defaults to shared.
    init(
        fileStorage: FileStorageService = .shared,
        entitlementManager: EntitlementManager = .shared
    ) {
        self.fileStorage = fileStorage
        self.entitlementManager = entitlementManager
    }

    // MARK: - Model Context Setup

    /// Configures the repository with a model context.
    ///
    /// Must be called before any database operations. Typically called
    /// during app initialization or view setup with the environment's context.
    ///
    /// - Parameter context: The `ModelContext` to use for operations.
    func configure(with context: ModelContext) {
        self.modelContext = context
    }

    /// Validates that the model context is available.
    ///
    /// - Throws: `ReportRepositoryError.contextNotAvailable` if no context is set.
    private func validateContext() throws -> ModelContext {
        guard let context = modelContext else {
            throw ReportRepositoryError.contextNotAvailable
        }
        return context
    }

    // MARK: - CRUD Operations - Create

    /// Inserts a new inspection report into the database.
    ///
    /// This method also increments the report creation count via `EntitlementManager`.
    ///
    /// - Parameter report: The `InspectionReport` to insert.
    /// - Throws: `ReportRepositoryError.saveFailed` if the save operation fails.
    ///           `EntitlementError.freeLimitReached` if the free tier limit is exceeded.
    func insert(_ report: InspectionReport) async throws {
        let context = try validateContext()

        // Check entitlement before creating
        try entitlementManager.validateCanCreateReport()

        context.insert(report)

        do {
            try context.save()
            entitlementManager.incrementReportCount()
        } catch {
            throw ReportRepositoryError.saveFailed(underlying: error)
        }
    }

    /// Creates and inserts a new inspection report with the given properties.
    ///
    /// - Parameters:
    ///   - title: The report title.
    ///   - propertyName: Name of the property being inspected.
    ///   - propertyAddress: Address of the property.
    ///   - reportType: The type of inspection report.
    /// - Returns: The newly created `InspectionReport`.
    /// - Throws: `ReportRepositoryError.saveFailed` or `EntitlementError`.
    @discardableResult
    func createReport(
        title: String,
        propertyName: String,
        propertyAddress: String,
        reportType: ReportType
    ) async throws -> InspectionReport {
        let report = InspectionReport(
            title: title,
            propertyName: propertyName,
            propertyAddress: propertyAddress,
            reportType: reportType
        )
        try await insert(report)
        return report
    }

    // MARK: - CRUD Operations - Read

    /// Fetches all inspection reports with optional sorting.
    ///
    /// - Parameter sortOrder: The sort order for results. Defaults to `.newestFirst`.
    /// - Returns: An array of all `InspectionReport` objects.
    /// - Throws: `ReportRepositoryError.fetchFailed` if the fetch fails.
    func fetchAll(sortOrder: ReportSortOrder = .newestFirst) async throws -> [InspectionReport] {
        let context = try validateContext()

        let descriptor = FetchDescriptor<InspectionReport>(
            sortBy: sortDescriptors(for: sortOrder)
        )

        do {
            return try context.fetch(descriptor)
        } catch {
            throw ReportRepositoryError.fetchFailed(underlying: error)
        }
    }

    /// Fetches a single report by its unique identifier.
    ///
    /// - Parameter id: The `UUID` of the report to fetch.
    /// - Returns: The matching `InspectionReport`, or `nil` if not found.
    /// - Throws: `ReportRepositoryError.fetchFailed` if the fetch fails.
    func fetchByID(_ id: UUID) async throws -> InspectionReport? {
        let context = try validateContext()

        let descriptor = FetchDescriptor<InspectionReport>(
            predicate: #Predicate { $0.id == id }
        )

        do {
            let results = try context.fetch(descriptor)
            return results.first
        } catch {
            throw ReportRepositoryError.fetchFailed(underlying: error)
        }
    }

    /// Fetches reports matching the given filter criteria.
    ///
    /// - Parameters:
    ///   - criteria: The filter criteria to apply.
    ///   - sortOrder: The sort order for results. Defaults to `.newestFirst`.
    /// - Returns: An array of matching `InspectionReport` objects.
    /// - Throws: `ReportRepositoryError.fetchFailed` if the fetch fails.
    func fetchFiltered(
        criteria: ReportFilterCriteria,
        sortOrder: ReportSortOrder = .newestFirst
    ) async throws -> [InspectionReport] {
        let context = try validateContext()

        let descriptor = FetchDescriptor<InspectionReport>(
            sortBy: sortDescriptors(for: sortOrder)
        )

        do {
            var results = try context.fetch(descriptor)

            if let status = criteria.status {
                results = results.filter { $0.status == status }
            }

            if let reportType = criteria.reportType {
                results = results.filter { $0.reportType == reportType }
            }

            if let dateRange = criteria.dateRange {
                results = results.filter { dateRange.contains($0.createdAt) }
            }

            if let searchText = criteria.searchText, !searchText.isEmpty {
                let lowercasedQuery = searchText.lowercased()
                results = results.filter { report in
                    let titleMatch = report.title.lowercased().contains(lowercasedQuery)
                    let propertyMatch = report.propertyName.lowercased().contains(lowercasedQuery)
                    let addressMatch = report.propertyAddress.lowercased().contains(lowercasedQuery)
                    return titleMatch || propertyMatch || addressMatch
                }
            }

            return results
        } catch {
            throw ReportRepositoryError.fetchFailed(underlying: error)
        }
    }

    // MARK: - CRUD Operations - Update

    /// Saves changes to an existing report.
    ///
    /// - Parameter report: The `InspectionReport` with updated values.
    /// - Throws: `ReportRepositoryError.saveFailed` if the save fails.
    func update(_ report: InspectionReport) async throws {
        let context = try validateContext()

        // Touch the updated timestamp
        report.updatedAt = Date()

        do {
            try context.save()
        } catch {
            throw ReportRepositoryError.saveFailed(underlying: error)
        }
    }

    /// Updates a report's status.
    ///
    /// - Parameters:
    ///   - report: The report to update.
    ///   - status: The new `ReportStatus`.
    /// - Throws: `ReportRepositoryError.saveFailed` if the save fails.
    func updateStatus(for report: InspectionReport, to status: ReportStatus) async throws {
        report.status = status
        try await update(report)
    }

    /// Updates a report's basic information.
    ///
    /// - Parameters:
    ///   - report: The report to update.
    ///   - title: Optional new title.
    ///   - propertyName: Optional new property name.
    ///   - propertyAddress: Optional new property address.
    /// - Throws: `ReportRepositoryError.saveFailed` if the save fails.
    func updateReportInfo(
        for report: InspectionReport,
        title: String? = nil,
        propertyName: String? = nil,
        propertyAddress: String? = nil
    ) async throws {
        if let title = title { report.title = title }
        if let propertyName = propertyName { report.propertyName = propertyName }
        if let propertyAddress = propertyAddress { report.propertyAddress = propertyAddress }
        try await update(report)
    }

    // MARK: - CRUD Operations - Delete

    /// Deletes a report and all its associated files.
    ///
    /// This removes the report from the database and deletes all related
    /// images, thumbnails, and PDFs from disk.
    ///
    /// - Parameter report: The `InspectionReport` to delete.
    /// - Throws: `ReportRepositoryError.deleteFailed` if deletion fails.
    func delete(_ report: InspectionReport) async throws {
        let context = try validateContext()

        // Delete associated files first
        do {
            try fileStorage.deleteAllFiles(for: report)
        } catch {
            // Log but continue with model deletion even if file cleanup fails
            print("Warning: Failed to delete some files for report \(report.id): \(error.localizedDescription)")
        }

        // Delete from model context
        context.delete(report)

        do {
            try context.save()
        } catch {
            throw ReportRepositoryError.deleteFailed(underlying: error)
        }
    }

    /// Deletes a report by its ID.
    ///
    /// - Parameter id: The `UUID` of the report to delete.
    /// - Throws: `ReportRepositoryError.reportNotFound` if the report doesn't exist.
    ///           `ReportRepositoryError.deleteFailed` if deletion fails.
    func deleteByID(_ id: UUID) async throws {
        guard let report = try await fetchByID(id) else {
            throw ReportRepositoryError.reportNotFound
        }
        try await delete(report)
    }

    /// Deletes multiple reports and their associated files.
    ///
    /// - Parameter reports: The reports to delete.
    /// - Throws: `ReportRepositoryError.deleteFailed` if any deletion fails.
    func deleteMultiple(_ reports: [InspectionReport]) async throws {
        for report in reports {
            try await delete(report)
        }
    }

    // MARK: - Search

    /// Searches reports by title, property name, or property address.
    ///
    /// - Parameters:
    ///   - query: The search text (case-insensitive).
    ///   - sortOrder: The sort order for results.
    /// - Returns: Matching `InspectionReport` objects.
    /// - Throws: `ReportRepositoryError.fetchFailed` if the search fails.
    func search(query: String, sortOrder: ReportSortOrder = .newestFirst) async throws -> [InspectionReport] {
        let criteria = ReportFilterCriteria(searchText: query)
        return try await fetchFiltered(criteria: criteria, sortOrder: sortOrder)
    }

    /// Searches for reports containing issues with titles matching the query.
    ///
    /// - Parameter query: The search text for issue titles.
    /// - Returns: Reports that contain matching issues.
    func searchByIssueTitle(query: String) async throws -> [InspectionReport] {
        let context = try validateContext()
        let lowercasedQuery = query.lowercased()

        let descriptor = FetchDescriptor<InspectionReport>(
            sortBy: sortDescriptors(for: .newestFirst)
        )

        do {
            let allReports = try context.fetch(descriptor)
            return allReports.filter { report in
                guard let issues = report.issues else { return false }
                return issues.contains { issue in
                    issue.title.lowercased().contains(lowercasedQuery)
                }
            }
        } catch {
            throw ReportRepositoryError.fetchFailed(underlying: error)
        }
    }

    // MARK: - Statistics

    /// Returns statistics about the stored reports.
    ///
    /// - Returns: A `ReportStatistics` struct containing counts and breakdowns.
    func statistics() async throws -> ReportStatistics {
        let context = try validateContext()

        let descriptor = FetchDescriptor<InspectionReport>()
        let allReports: [InspectionReport]
        do {
            allReports = try context.fetch(descriptor)
        } catch {
            throw ReportRepositoryError.fetchFailed(underlying: error)
        }

        let totalReports = allReports.count
        let totalIssues = allReports.reduce(0) { $0 + ($1.issues?.count ?? 0) }
        let totalAreas = allReports.reduce(0) { $0 + ($1.areas?.count ?? 0) }

        // Count by status
        var statusCounts: [ReportStatus: Int] = [:]
        for report in allReports {
            statusCounts[report.status, default: 0] += 1
        }

        // Count by type
        var typeCounts: [ReportType: Int] = [:]
        for report in allReports {
            typeCounts[report.reportType, default: 0] += 1
        }

        // Recent reports (last 30 days)
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let recentReports = allReports.filter {
            $0.createdAt >= thirtyDaysAgo
        }.count

        return ReportStatistics(
            totalReports: totalReports,
            totalIssues: totalIssues,
            totalAreas: totalAreas,
            statusCounts: statusCounts,
            typeCounts: typeCounts,
            recentReports: recentReports
        )
    }

    // MARK: - Private Helpers

    /// Converts a `ReportSortOrder` to SwiftData sort descriptors.
    ///
    /// - Parameter sortOrder: The desired sort order.
    /// - Returns: An array of `SortDescriptor` objects.
    private func sortDescriptors(for sortOrder: ReportSortOrder) -> [SortDescriptor<InspectionReport>] {
        switch sortOrder {
        case .newestFirst:
            return [SortDescriptor(\.createdAt, order: .reverse)]
        case .oldestFirst:
            return [SortDescriptor(\.createdAt, order: .forward)]
        case .titleAscending:
            return [SortDescriptor(\.title, order: .forward)]
        case .titleDescending:
            return [SortDescriptor(\.title, order: .reverse)]
        case .propertyNameAscending:
            return [SortDescriptor(\.propertyName, order: .forward)]
        }
    }
}

// MARK: - Report Statistics

/// Aggregated statistics about stored inspection reports.
struct ReportStatistics {
    /// Total number of inspection reports.
    let totalReports: Int
    /// Total number of issues across all reports.
    let totalIssues: Int
    /// Total number of inspected areas across all reports.
    let totalAreas: Int
    /// Breakdown of reports by status.
    let statusCounts: [ReportStatus: Int]
    /// Breakdown of reports by type.
    let typeCounts: [ReportType: Int]
    /// Number of reports created in the last 30 days.
    let recentReports: Int

    /// Average number of issues per report.
    var averageIssuesPerReport: Double {
        totalReports > 0 ? Double(totalIssues) / Double(totalReports) : 0
    }

    /// Whether there are any reports stored.
    var hasData: Bool { totalReports > 0 }
}

// MARK: - Predicate Extensions
