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
    @State private var showHelp = false
    @State private var showAllReports = false
    @State private var pendingJourney: HomeJourneyIntent?
    @State private var showReportChooser = false

    /// SwiftData query for all inspection reports, sorted by creation date (newest first).
    @Query(sort: \InspectionReport.createdAt, order: .reverse)
    private var reports: [InspectionReport]

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .top) {
            LinearGradient(
                colors: [Theme.blueSurfaceStrong, Theme.background, Theme.background],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

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
        }
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
        .sheet(isPresented: $showHelp) {
            NavigationStack {
                HelpCenterView()
            }
        }
        .confirmationDialog(
            pendingJourney?.dialogTitle ?? "Open report",
            isPresented: pendingJourneyDialogBinding,
            titleVisibility: .visible
        ) {
            if let latestReport = reports.first {
                Button("Continue \(latestReport.propertyName)") {
                    continuePendingJourney(with: latestReport)
                }
            }

            Button("Choose Existing Report") {
                showReportChooser = true
            }

            Button("Start New Report") {
                createNewReportForPendingJourney()
            }

            Button("Cancel", role: .cancel) {
                pendingJourney = nil
            }
        } message: {
            Text(pendingJourney?.dialogMessage ?? "Choose where this task should happen.")
        }
        .sheet(isPresented: $showReportChooser) {
            NavigationStack {
                ReportChooserView(reports: reports) { report in
                    showReportChooser = false
                    continuePendingJourney(with: report)
                }
            }
        }
    }

    // MARK: - Header

    /// The app header with title and subtitle.
    private var headerView: some View {
        VStack(alignment: .leading, spacing: Theme.spacingXL) {
            topBar

            VStack(alignment: .leading, spacing: Theme.spacingXS) {
                Text("SnagSnap")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Theme.secondaryLabel)

                Text(reports.isEmpty ? "Start a property report." : "What needs attention today?")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(Theme.ink)
                    .lineSpacing(-2)
                    .minimumScaleFactor(0.76)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Theme.spacingL)
    }

    private var topBar: some View {
        HStack {
            CircleIconButton(systemName: "questionmark.bubble", label: "Help") {
                HapticService.shared.play(.light)
                showHelp = true
            }

            Spacer()

            CircleIconButton(systemName: "plus", label: "Create new report") {
                HapticService.shared.play(.medium)
                router.navigateToCreateReport()
            }
        }
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
        .padding(.horizontal, Theme.spacingL)
    }

    // MARK: - Recent Reports Section

    /// The recent reports section containing header, search bar, and report list.
    @ViewBuilder
    private var recentReportsSection: some View {
        if reports.isEmpty {
            quickStartGrid
        } else {
            VStack(spacing: Theme.spacingS) {
                // Section header
                HStack {
                    Text("Recent Reports")
                        .font(Theme.fontHeadline)
                        .foregroundStyle(Theme.label)

                    Spacer()

                    if viewModel.filteredReports(from: reports).count > 5 {
                        Button(showAllReports ? "Show Less" : "See All") {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                showAllReports.toggle()
                            }
                        }
                        .font(Theme.fontSubheadline)
                        .foregroundStyle(Theme.primary)
                    }
                }
                .padding(.horizontal, Theme.spacingL)

                // Search bar
                searchBar

                // Report list
                reportList
            }
        }
    }

    private var quickStartGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: Theme.spacingM),
            GridItem(.flexible(), spacing: Theme.spacingM)
        ], spacing: Theme.spacingM) {
            HomeActionTile(
                icon: "doc.badge.plus",
                title: "Create",
                subtitle: "Start with property details"
            ) {
                HapticService.shared.play(.medium)
                router.navigateToCreateReport()
            }

            HomeActionTile(
                icon: "camera.viewfinder",
                title: "Capture",
                subtitle: "Add inspection photos"
            ) {
                startWorkspaceJourney(.capture)
            }

            HomeActionTile(
                icon: "square.grid.2x2",
                title: "Organize",
                subtitle: "Areas, issues, notes"
            ) {
                startWorkspaceJourney(.organize)
            }

            HomeActionTile(
                icon: "doc.richtext",
                title: "Export",
                subtitle: "Generate polished PDFs"
            ) {
                startWorkspaceJourney(.export)
            }
        }
        .padding(.horizontal, Theme.spacingL)
        .scaleEntryAnimation(delay: 0.1)
    }

    private func startWorkspaceJourney(_ intent: HomeJourneyIntent) {
        HapticService.shared.play(.medium)

        if reports.first != nil {
            pendingJourney = intent
            return
        }

        guard EntitlementManager.shared.canCreateNewReport() else {
            router.navigateToCreateReport(targetTab: intent.tab, launchAction: intent.launchAction)
            return
        }

        if intent == .export {
            router.navigateToCreateReport(targetTab: intent.tab, launchAction: intent.launchAction)
            return
        }

        let report = InspectionReport(
            title: "Draft Property Report",
            propertyName: "New Property",
            propertyAddress: "Address to add",
            reportType: .general,
            generalNotes: "Created from the \(intent.tab.rawValue.lowercased()) quick start. Complete the property details before sharing."
        )
        modelContext.insert(report)

        do {
            try modelContext.save()
            router.navigateToReport(report, initialTab: intent.tab, launchAction: intent.launchAction)
        } catch {
            toastMessage = "Could not start report"
            showToast = true
            router.navigateToCreateReport(targetTab: intent.tab, launchAction: intent.launchAction)
        }
    }

    private var pendingJourneyDialogBinding: Binding<Bool> {
        Binding(
            get: { pendingJourney != nil && !showReportChooser },
            set: { isPresented in
                if !isPresented && !showReportChooser {
                    pendingJourney = nil
                }
            }
        )
    }

    private func continuePendingJourney(with report: InspectionReport) {
        guard let intent = pendingJourney else { return }
        pendingJourney = nil
        router.navigateToReport(report, initialTab: intent.tab, launchAction: intent.launchAction)
    }

    private func createNewReportForPendingJourney() {
        guard let intent = pendingJourney else { return }
        pendingJourney = nil
        router.navigateToCreateReport(targetTab: intent.tab, launchAction: intent.launchAction)
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
                .fill(Theme.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radiusMedium, style: .continuous)
                .stroke(Theme.separator, lineWidth: 0.5)
        )
        .padding(.horizontal, Theme.spacingL)
    }

    // MARK: - Report List

    /// The list of report cards, filtered by search text.
    @ViewBuilder
    private var reportList: some View {
        let filtered = viewModel.filteredReports(from: reports)
        let recent = showAllReports ? filtered : Array(filtered.prefix(5))

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
                    .padding(.horizontal, Theme.spacingL)
                    .animateOnAppear(delay: 0.1 + Double(index) * 0.03, duration: 0.4)
                }
            }
        }
    }
}

private struct CircleIconButton: View {
    let systemName: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 21, weight: .medium))
                .foregroundStyle(Theme.ink)
                .frame(width: 58, height: 58)
                .background(.white.opacity(0.82))
                .clipShape(Circle())
                .overlay(Circle().stroke(.white.opacity(0.9), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

private struct HomeActionTile: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Theme.spacingL) {
                Image(systemName: icon)
                    .font(.system(size: 30, weight: .regular))
                    .foregroundStyle(Theme.primary.opacity(0.42))
                    .frame(width: 44, height: 44, alignment: .leading)

                VStack(alignment: .leading, spacing: Theme.spacingXS) {
                    Text(title)
                        .font(.system(size: 25, weight: .bold))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)

                    Text(subtitle)
                        .font(Theme.fontSubheadline)
                        .foregroundStyle(Theme.secondaryLabel)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 154, alignment: .leading)
            .padding(Theme.spacingM)
            .background(Theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusLarge, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radiusLarge, style: .continuous)
                    .stroke(.white.opacity(0.75), lineWidth: 1)
            )
        }
        .buttonStyle(.animated(haptic: .light))
    }
}

private enum HomeJourneyIntent: Equatable {
    case capture
    case organize
    case export

    var tab: WorkspaceTab {
        switch self {
        case .capture: return .issues
        case .organize: return .areas
        case .export: return .report
        }
    }

    var launchAction: WorkspaceLaunchAction {
        switch self {
        case .capture: return .addIssue
        case .organize: return .addArea
        case .export: return .none
        }
    }

    var dialogTitle: String {
        switch self {
        case .capture: return "Capture into which report?"
        case .organize: return "Organize which report?"
        case .export: return "Export which report?"
        }
    }

    var dialogMessage: String {
        switch self {
        case .capture:
            return "Choose the report that should receive the new issue and photos."
        case .organize:
            return "Choose the report where you want to add areas or edit structure."
        case .export:
            return "Choose the report to review before generating a PDF."
        }
    }
}

private struct ReportChooserView: View {
    @Environment(\.dismiss) private var dismiss

    let reports: [InspectionReport]
    let onSelect: (InspectionReport) -> Void

    var body: some View {
        List {
            Section {
                ForEach(reports) { report in
                    Button {
                        onSelect(report)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(report.title)
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(Theme.ink)
                            Text(report.propertyAddress)
                                .font(.subheadline)
                                .foregroundStyle(Theme.secondaryLabel)
                                .lineLimit(2)
                            Text(report.summaryDescription)
                                .font(.caption)
                                .foregroundStyle(Theme.primary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            } header: {
                Text("Choose Report")
            } footer: {
                Text("Your next action will happen inside the selected report.")
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Reports")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
    }
}

struct HelpCenterView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.spacingL) {
                VStack(alignment: .leading, spacing: Theme.spacingS) {
                    Text("Help")
                        .font(.system(size: 38, weight: .bold))
                        .foregroundStyle(Theme.ink)

                    Text("Build a complete property report in four steps.")
                        .font(Theme.fontBody)
                        .foregroundStyle(Theme.secondaryLabel)
                }

                helpStep("1", "Create a report", "Add the property, report type, inspection date, client, inspector, and notes.")
                helpStep("2", "Add areas", "Break the property into rooms or zones so issues are easy to review.")
                helpStep("3", "Capture issues", "Record severity, status, notes, and photos. Annotate photos before export when needed.")
                helpStep("4", "Export PDF", "Use the Report tab to generate, preview, and share the finished PDF.")

                SSCard(padding: Theme.spacingL, cornerRadius: Theme.radiusLarge) {
                    VStack(alignment: .leading, spacing: Theme.spacingS) {
                        Text("Support")
                            .font(Theme.fontHeadline)
                            .foregroundStyle(Theme.ink)
                        Text("For help, email support@snagsnap.app. Include your app version from Settings and a short description of what happened.")
                            .font(Theme.fontBody)
                            .foregroundStyle(Theme.secondaryLabel)
                    }
                }
            }
            .padding(Theme.spacingL)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Help")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
    }

    private func helpStep(_ number: String, _ title: String, _ body: String) -> some View {
        HStack(alignment: .top, spacing: Theme.spacingM) {
            Text(number)
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(Theme.primary, in: Circle())

            VStack(alignment: .leading, spacing: Theme.spacingXS) {
                Text(title)
                    .font(Theme.fontHeadline)
                    .foregroundStyle(Theme.ink)
                Text(body)
                    .font(Theme.fontBody)
                    .foregroundStyle(Theme.secondaryLabel)
            }
        }
        .padding(Theme.spacingL)
        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: Theme.radiusLarge, style: .continuous))
    }
}

// MARK: - Preview

#Preview("Home Dashboard") {
    NavigationStack {
        HomeDashboardView()
    }
    .modelContainer(for: [InspectionReport.self, InspectionArea.self, InspectionIssue.self, IssuePhoto.self])
}
