// SnagSnap
// HomeDashboardView.swift
//
// The main home screen with stats, CTA, recent reports list, and search.

import SwiftUI
import SwiftData
import Foundation

// MARK: - Home Dashboard View

/// The main home dashboard screen for SnagSnap.
///
/// Displays app branding, summary statistics, a primary call-to-action,
/// a searchable list of recent reports, and an empty state when no reports exist.
/// Supports pull-to-refresh and swipe-to-delete on report cards.
struct HomeDashboardView: View {

    // MARK: - Environment & State

    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = HomeViewModel()
    @State private var router = AppRouter.shared
    @State private var showDeleteToast = false
    @State private var toastMessage = ""
    @State private var showToast = false
    @State private var isRefreshing = false

    /// SwiftData query for all inspection reports, sorted by creation date (newest first).
    @Query(sort: \InspectionReport.createdAt, order: .reverse)
    private var reports: [InspectionReport]

    // MARK: - Body

    var body: some View {
        ScrollView {
            LazyVStack(spacing: reports.isEmpty ? Theme.spacingXL : Theme.spacingL, pinnedViews: []) {
                // MARK: Header
                headerView

                // MARK: Stats Row
                if !reports.isEmpty {
                    StatsSummaryView(stats: viewModel.calculateStats(from: reports))
                }

                // MARK: Primary CTA
                if !reports.isEmpty {
                    newReportButton
                }

                // MARK: Recent Reports Section
                recentReportsSection
            }
            .padding(.top, Theme.spacingXL)
            .padding(.bottom, Theme.spacingXXL)
        }
        .background(Theme.groupedBackground)
        .scrollContentBackground(.hidden)
        .refreshable {
            isRefreshing = true
            viewModel.refresh()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isRefreshing = false
            }
        }
        .sensoryFeedback(.impact, trigger: isRefreshing)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") { viewModel.clearError() }
        } message: {
            Text(viewModel.errorMessage ?? "An unknown error occurred.")
        }
        .onAppear {
            viewModel.configure(with: modelContext)
        }
        .toast(isPresented: $showToast, message: toastMessage, style: .success, duration: 2.0)
    }

    // MARK: - Header

    /// The app header with title and subtitle.
    private var headerView: some View {
        HStack(alignment: .top, spacing: Theme.spacingM) {
            VStack(alignment: .leading, spacing: Theme.spacingXS) {
                Text("SnagSnap")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.label)

                Text("Property Reports")
                    .font(Theme.fontTitle3)
                    .foregroundStyle(Theme.secondaryLabel)
            }

            Spacer(minLength: Theme.spacingM)

            Button(action: {
                HapticService.shared.play(.medium)
                router.navigateToCreateReport()
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Theme.primary)
                    .frame(width: 56, height: 56)
                    .background(Theme.secondaryGroupedBackground)
                    .clipShape(Circle())
                    .shadow(color: Theme.shadowColor, radius: Theme.shadowRadiusLarge, x: 0, y: Theme.shadowYOffsetMedium)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Create new report")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Theme.spacingM)
    }

    // MARK: - New Report Button

    /// The primary call-to-action button for creating a new report.
    private var newReportButton: some View {
        SSButton(
            "New Report",
            style: .primary,
            icon: "plus",
            isFullWidth: true
        ) {
            HapticService.shared.play(.success)
            router.navigateToCreateReport()
        }
        .buttonStyle(.animated(haptic: .medium))
        .accessibilityLabel("Create new report")
        .padding(.horizontal, Theme.spacingM)
    }

    // MARK: - Recent Reports Section

    /// The recent reports section containing header, search bar, and report list.
    @ViewBuilder
    private var recentReportsSection: some View {
        if reports.isEmpty {
            NoReportsEmptyState {
                router.navigateToCreateReport()
            }
            .scaleEntryAnimation(delay: 0.1)
            .padding(.top, Theme.spacingXL)
        } else {
            VStack(spacing: Theme.spacingS) {
                // Section header
                HStack {
                    Text("Recent Reports")
                        .font(Theme.fontHeadline)
                        .foregroundStyle(Theme.label)

                    Spacer()

                    if reports.count > 5 {
                        Button("See All") {
                            // Future: navigate to full reports list
                        }
                        .font(Theme.fontSubheadline)
                        .foregroundStyle(Theme.primary)
                    }
                }
                .padding(.horizontal, Theme.spacingM)

                // Search bar
                searchBar

                // Report list
                reportList
            }
        }
    }

    // MARK: - Search Bar

    /// The search bar for filtering reports.
    @ViewBuilder
    private var searchBar: some View {
        HStack(spacing: Theme.spacingS) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(Theme.tertiaryLabel)

            TextField("Search by title, property, or address...", text: $viewModel.searchText)
                .font(Theme.fontBody)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            if !viewModel.searchText.isEmpty {
                Button(action: { viewModel.searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Theme.tertiaryLabel)
                }
                .buttonStyle(.plain)
                .transition(.opacity)
            }
        }
        .padding(.horizontal, Theme.spacingM)
        .padding(.vertical, Theme.spacingS)
        .background(
            RoundedRectangle(cornerRadius: Theme.radiusMedium, style: .continuous)
                .fill(Theme.secondaryGroupedBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radiusMedium, style: .continuous)
                .stroke(Theme.separator, lineWidth: 0.5)
        )
        .padding(.horizontal, Theme.spacingM)
    }

    // MARK: - Report List

    /// The list of report cards, filtered by search text.
    @ViewBuilder
    private var reportList: some View {
        let filtered = viewModel.filteredReports(from: reports)
        let recent = Array(filtered.prefix(5))

        if recent.isEmpty && !viewModel.searchText.isEmpty {
            // No search results
            NoSearchResultsEmptyState(query: viewModel.searchText) {
                viewModel.searchText = ""
            }
            .frame(minHeight: 300)
        } else {
            LazyVStack(spacing: Theme.spacingM) {
                ForEach(Array(recent.enumerated()), id: \.element.id) { index, report in
                    ReportCardView(
                        report: report,
                        onDelete: { reportToDelete in
                            HapticService.shared.play(.success)
                            toastMessage = "Report deleted"
                            showToast = true
                            viewModel.deleteReport(reportToDelete)
                        },
                        onTap: {
                            HapticService.shared.play(.medium)
                            router.navigateToReport(report)
                        }
                    )
                    .accessibilityLabel("Report: \(report.title)")
                    .padding(.horizontal, Theme.spacingM)
                    .animateOnAppear(delay: 0.1 + Double(index) * 0.03, duration: 0.4)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Home Dashboard") {
    NavigationStack {
        HomeDashboardView()
    }
    .modelContainer(for: [InspectionReport.self, InspectionArea.self, InspectionIssue.self, IssuePhoto.self])
}
