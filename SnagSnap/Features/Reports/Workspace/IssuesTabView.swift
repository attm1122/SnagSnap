// SnagSnap
// IssuesTabView.swift
//
// Issues tab for the report workspace. Supports filtering, sorting,
// and displays issues using the reusable IssueCardView.

import SwiftUI
import SwiftData

// MARK: - IssuesTabView

/// Displays all inspection issues within a report with filtering and sorting controls.
struct IssuesTabView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(AppRouter.self) private var router

    let report: InspectionReport
    let viewModel: ReportWorkspaceViewModel

    // MARK: - Local State

    @State private var showFilterSheet = false

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Filter & Sort toolbar
            filterSortBar
                .padding(.horizontal, Theme.spacingM)
                .padding(.bottom, Theme.spacingS)

            // Issues list
            let issues = viewModel.sortedAndFilteredIssues(from: report)

            if issues.isEmpty {
                emptyState
            } else {
                issuesList(issues: issues)
                    .padding(.horizontal, Theme.spacingM)
            }
        }
        .padding(.top, Theme.spacingS)
    }

    // MARK: - Filter & Sort Bar

    private var filterSortBar: some View {
        HStack(spacing: Theme.spacingS) {
            // Filter picker
            Menu {
                Picker("Filter", selection: $viewModel.issueFilter) {
                    ForEach(IssueFilter.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "line.3.horizontal.decrease")
                        .font(.caption.weight(.semibold))
                    Text(viewModel.issueFilter.rawValue)
                        .font(.subheadline.weight(.medium))
                }
                .foregroundStyle(Theme.primary)
                .padding(.horizontal, Theme.spacingM)
                .padding(.vertical, Theme.spacingS)
                .background(Theme.primary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMedium, style: .continuous))
            }

            // Sort picker
            Menu {
                Picker("Sort", selection: $viewModel.issueSort) {
                    ForEach(IssueSort.allCases) { sort in
                        Text(sort.rawValue).tag(sort)
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.caption.weight(.semibold))
                    Text(viewModel.issueSort.rawValue)
                        .font(.subheadline.weight(.medium))
                }
                .foregroundStyle(.secondary)
                .padding(.horizontal, Theme.spacingM)
                .padding(.vertical, Theme.spacingS)
                .background(Color.gray.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMedium, style: .continuous))
            }

            Spacer()

            // Issue count badge
            let issues = viewModel.sortedAndFilteredIssues(from: report)
            Text("\(issues.count) issue\(issues.count == 1 ? "" : "s")")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Issues List

    private func issuesList(issues: [InspectionIssue]) -> some View {
        LazyVStack(spacing: Theme.spacingM) {
            ForEach(issues) { issue in
                Button {
                    router.navigateToIssueEditor(issue: issue, area: issue.area, report: report)
                } label: {
                    IssueCardView(issue: issue)
                }
                .buttonStyle(.plain)
                .contextMenu {
                    Button {
                        router.navigateToIssueEditor(issue: issue, area: issue.area, report: report)
                    } label: {
                        Label("Edit Issue", systemImage: "pencil")
                    }

                    if !issue.isResolved {
                        Button {
                            markIssueFixed(issue)
                        } label: {
                            Label("Mark Fixed", systemImage: "checkmark.circle")
                        }
                    }

                    Button(role: .destructive) {
                        deleteIssue(issue)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: Theme.spacingL) {
            if (report.issues?.count ?? 0) > 0 && viewModel.issueFilter != .all {
                // Filtered empty state
                SSEmptyState(
                    icon: "magnifyingglass",
                    title: "No Matching Issues",
                    message: "No issues match the current filter. Try changing the filter to see all issues.",
                    buttonTitle: "Show All",
                    buttonAction: {
                        viewModel.issueFilter = .all
                    }
                )
            } else {
                // Truly empty state
                SSEmptyState(
                    icon: "exclamationmark.triangle",
                    title: "No Issues Yet",
                    message: "Add issues to document problems found during the inspection.",
                    buttonTitle: "Add Issue",
                    buttonAction: {
                        if let firstArea = report.areas?.first {
                            router.navigateToIssueEditor(issue: nil, area: firstArea, report: report)
                        } else {
                            viewModel.showAddAreaSheet = true
                        }
                    }
                )
            }
        }
        .padding(.top, Theme.spacingXXL)
    }

    // MARK: - Actions

    private func markIssueFixed(_ issue: InspectionIssue) {
        issue.status = .fixed
        issue.updatedAt = Date()
        report.updatedAt = Date()
        try? modelContext.save()
    }

    private func deleteIssue(_ issue: InspectionIssue) {
        report.issues?.removeAll { $0.id == issue.id }
        report.updatedAt = Date()
        modelContext.delete(issue)
        try? modelContext.save()
    }
}

// MARK: - Preview

#Preview("Issues Tab") {
    let schema = Schema([InspectionReport.self, InspectionArea.self, InspectionIssue.self, IssuePhoto.self])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [config])
    let context = ModelContext(container)

    let report = InspectionReport(
        title: "Sample Report",
        propertyName: "15 Oak Avenue",
        propertyAddress: "15 Oak Avenue, Manchester M1 1AA",
        reportType: .moveIn
    )
    context.insert(report)

    let kitchen = InspectionArea(name: "Kitchen")
    context.insert(kitchen)
    kitchen.report = report
    report.areas = [kitchen]

    let issue1 = InspectionIssue(title: "Cracked tile near sink", notes: "Visible crack in ceramic tile next to sink. Water may seep through.", severity: .high, status: .open)
    context.insert(issue1)
    issue1.report = report
    issue1.area = kitchen

    let issue2 = InspectionIssue(title: "Loose door handle", severity: .low, status: .fixed)
    context.insert(issue2)
    issue2.report = report
    issue2.area = kitchen

    let issue3 = InspectionIssue(title: "Water stain on ceiling", notes: "Discoloration indicating possible leak from above", severity: .urgent, status: .open)
    context.insert(issue3)
    issue3.report = report
    issue3.area = kitchen

    let issue4 = InspectionIssue(title: "Scuffed paintwork on wall", severity: .medium, status: .inProgress)
    context.insert(issue4)
    issue4.report = report
    issue4.area = kitchen

    let issue5 = InspectionIssue(title: "Missing sealant around bath", severity: .high, status: .open)
    context.insert(issue5)
    issue5.report = report
    issue5.area = kitchen

    report.issues = [issue1, issue2, issue3, issue4, issue5]
    try? context.save()

    let vm = ReportWorkspaceViewModel()

    return ScrollView {
        IssuesTabView(report: report, viewModel: vm)
            .padding(.top, Theme.spacingS)
    }
    .background(Theme.groupedBackground)
    .modelContainer(container)
    .environment(AppRouter.shared)
}
