// SnagSnap
// HomeViewModel.swift
//
// View model for the home dashboard screen.

import SwiftUI
import SwiftData
import Foundation

// MARK: - Dashboard Stats

/// Aggregated statistics displayed on the home dashboard.
struct DashboardStats {
    let totalReports: Int
    let openIssues: Int
    let completedCount: Int

    static let zero = DashboardStats(totalReports: 0, openIssues: 0, completedCount: 0)
}

// MARK: - HomeViewModel

/// View model for the home dashboard.
///
/// Uses `@Observable` for iOS 17+ compatibility and integrates with
/// SwiftData via `@Query` for reactive updates.
@Observable
final class HomeViewModel {

    // MARK: - Properties

    /// The search query for filtering reports.
    var searchText: String = ""

    /// Whether data is currently loading.
    private(set) var isLoading: Bool = false

    /// Error message if an operation failed.
    private(set) var errorMessage: String?

    /// Whether an error alert should be shown.
    var showError: Bool = false

    // MARK: - Dependencies

    /// The report repository for CRUD operations.
    private let repository: ReportRepository

    /// The SwiftData model context.
    private var modelContext: ModelContext?

    // MARK: - Initialization

    /// Creates a new `HomeViewModel`.
    init(repository: ReportRepository = ReportRepository()) {
        self.repository = repository
    }

    // MARK: - Model Context Setup

    /// Configures the view model with a model context.
    func configure(with context: ModelContext) {
        self.modelContext = context
        repository.configure(with: context)
    }

    // MARK: - Filtering

    /// Filters an array of reports based on the current search text.
    func filteredReports(from reports: [InspectionReport]) -> [InspectionReport] {
        guard !searchText.isEmpty else { return reports }
        let lowercasedQuery = searchText.lowercased()
        return reports.filter { report in
            report.title.lowercased().contains(lowercasedQuery)
            || report.propertyName.lowercased().contains(lowercasedQuery)
            || report.propertyAddress.lowercased().contains(lowercasedQuery)
        }
    }

    // MARK: - Statistics

    /// Calculates dashboard statistics from the given reports.
    func calculateStats(from reports: [InspectionReport]) -> DashboardStats {
        let totalReports = reports.count
        let openIssues = reports.reduce(0) { $0 + $1.openIssueCount }
        let completedCount = reports.filter { $0.status == .exported || $0.status == .archived }.count

        return DashboardStats(
            totalReports: totalReports,
            openIssues: openIssues,
            completedCount: completedCount
        )
    }

    // MARK: - Delete

    /// Deletes a report and cleans up associated files.
    func deleteReport(_ report: InspectionReport) {
        guard let context = modelContext else {
            errorMessage = "Data context not available."
            showError = true
            return
        }

        repository.configure(with: context)

        Task {
            isLoading = true
            do {
                try await repository.delete(report)
                isLoading = false
            } catch {
                isLoading = false
                errorMessage = "Failed to delete report: \(report.title)"
                showError = true
            }
        }
    }

    // MARK: - Refresh

    /// Triggers a refresh of the data.
    func refresh() {
        errorMessage = nil
        showError = false
    }

    // MARK: - Error Handling

    /// Clears any active error state.
    func clearError() {
        errorMessage = nil
        showError = false
    }
}
