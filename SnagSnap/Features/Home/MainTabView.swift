// SnagSnap
// MainTabView.swift
//
// The root tab view managing the home and settings tabs.

import SwiftUI
import SwiftData
import Foundation

// MARK: - Main Tab View

/// The root tab view for the SnagSnap app.
///
/// Provides two tabs: Home (with dashboard) and Settings.
/// Each tab has its own `NavigationStack` with path-based navigation
/// managed by the shared `AppRouter`.
struct MainTabView: View {
    @State private var router = AppRouter.shared

    var body: some View {
        TabView(selection: $router.selectedTab) {
            // MARK: Home Tab
            NavigationStack(path: $router.homePath) {
                HomeDashboardView()
                    .navigationDestination(for: Route.self) { route in
                        routeDestination(for: route)
                    }
            }
            .tabItem {
                Label(AppRouter.Tab.home.title, systemImage: AppRouter.Tab.home.icon)
            }
            .tag(AppRouter.Tab.home)

            // MARK: Settings Tab
            NavigationStack(path: $router.settingsPath) {
                SettingsView()
                    .navigationDestination(for: Route.self) { route in
                        routeDestination(for: route)
                    }
            }
            .tabItem {
                Label(AppRouter.Tab.settings.title, systemImage: AppRouter.Tab.settings.icon)
            }
            .tag(AppRouter.Tab.settings)
        }
        .tint(Theme.primary)
    }

    // MARK: - Route Destinations

    /// Resolves a `Route` to its corresponding destination view.
    @ViewBuilder
    private func routeDestination(for route: Route) -> some View {
        switch route {
        case .createReport:
            Text("Create Report")
                .navigationTitle("New Report")

        case .reportWorkspace(let reportID):
            ReportWorkspaceView(reportID: reportID)

        case .issueEditor(let issueID, let areaID, let reportID):
            Text("Issue Editor")
                .navigationTitle(issueID == nil ? "New Issue" : "Edit Issue")

        case .areaEditor(let areaID, let reportID):
            Text("Area Editor")
                .navigationTitle(areaID == nil ? "New Area" : "Edit Area")

        case .photoAnnotation(let photoID):
            Text("Photo Annotation")
                .navigationTitle("Annotate Photo")

        case .pdfPreview(let reportID):
            Text("PDF Preview")
                .navigationTitle("Export PDF")

        case .paywall:
            Text("Paywall")
                .navigationTitle("Upgrade")

        case .settings:
            SettingsView()
        }
    }
}

// MARK: - Settings View

/// Placeholder settings view.
struct SettingsView: View {
    var body: some View {
        List {
            Section("Account") {
                NavigationLink(value: Route.paywall) {
                    Label("Upgrade to Pro", systemImage: Theme.iconStar)
                }
            }

            Section("App") {
                HStack {
                    Label("Version", systemImage: "info.circle")
                    Spacer()
                    Text("1.0.0")
                        .font(Theme.fontFootnote)
                        .foregroundStyle(Theme.secondaryLabel)
                }
            }
        }
        .navigationTitle("Settings")
        .background(Theme.groupedBackground)
    }
}

// MARK: - Report Workspace View

/// A workspace view for managing a specific inspection report.
///
/// Fetches the report from SwiftData using its ID and displays
/// report details, areas, and issues. Provides editing and export actions.
struct ReportWorkspaceView: View {
    let reportID: UUID

    @Environment(\.modelContext) private var modelContext
    @Query private var reports: [InspectionReport]

    /// The matched report fetched by ID.
    private var report: InspectionReport? {
        reports.first { $0.id == reportID }
    }

    init(reportID: UUID) {
        self.reportID = reportID
        _reports = Query(
            filter: #Predicate { $0.id == reportID }
        )
    }

    var body: some View {
        ScrollView {
            if let report = report {
                VStack(spacing: Theme.spacingL) {
                    // Report header card
                    reportHeaderCard(report)

                    // Areas section
                    areasSection(report)

                    // Issues section
                    issuesSection(report)
                }
                .padding(Theme.spacingM)
            } else {
                ContentUnavailableView(
                    "Report Not Found",
                    systemImage: "doc.text.magnifyingglass",
                    description: Text("The report you are looking for does not exist or has been deleted.")
                )
            }
        }
        .navigationTitle(report?.title ?? "Report")
        .navigationBarTitleDisplayMode(.large)
        .background(Theme.groupedBackground)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if let report = report {
                    Menu {
                        Button {
                            AppRouter.shared.navigateToPDFPreview(report: report)
                        } label: {
                            Label("Export PDF", systemImage: Theme.iconPDF)
                        }

                        Button {
                            // Share action
                        } label: {
                            Label("Share", systemImage: Theme.iconShare)
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 18, weight: .medium))
                    }
                }
            }
        }
    }

    // MARK: - Report Header Card

    private func reportHeaderCard(_ report: InspectionReport) -> some View {
        SSCard(padding: Theme.spacingL, cornerRadius: Theme.radiusLarge) {
            VStack(alignment: .leading, spacing: Theme.spacingM) {
                // Title and status
                HStack {
                    Text(report.title)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Theme.label)

                    Spacer()

                    StatusDot(color: report.status.color, size: 10)
                }

                // Property info
                VStack(alignment: .leading, spacing: 4) {
                    Label(report.propertyName, systemImage: "building.2")
                        .font(Theme.fontSubheadline)
                        .foregroundStyle(Theme.secondaryLabel)

                    Label(report.propertyAddress, systemImage: "mappin.and.ellipse")
                        .font(Theme.fontFootnote)
                        .foregroundStyle(Theme.tertiaryLabel)
                }

                Divider()

                // Stats row
                HStack(spacing: Theme.spacingXL) {
                    statColumn(icon: "square.grid.2x2", value: report.areaCount, label: "Areas")
                    statColumn(icon: "exclamationmark.triangle", value: report.issueCount, label: "Issues")
                    statColumn(icon: "photo", value: report.photoCount, label: "Photos")
                }

                // Report type and date
                HStack {
                    SSTag(report.reportType.displayName, variant: .info, icon: report.reportType.icon)

                    Spacer()

                    Text(report.displayDate)
                        .font(Theme.fontFootnote)
                        .foregroundStyle(Theme.secondaryLabel)
                }
            }
        }
    }

    private func statColumn(icon: String, value: Int, label: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(Theme.primary)

            Text("\(value)")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.label)

            Text(label)
                .font(Theme.fontCaption)
                .foregroundStyle(Theme.secondaryLabel)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Areas Section

    private func areasSection(_ report: InspectionReport) -> some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            SSSectionHeader(
                "Areas",
                actionTitle: "Add",
                actionIcon: "plus",
                action: {
                    AppRouter.shared.navigateToAreaEditor(area: nil, report: report)
                }
            )

            if let areas = report.areas, !areas.isEmpty {
                ForEach(areas) { area in
                    SSCard(padding: Theme.spacingM) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(area.name)
                                    .font(Theme.fontHeadline)
                                    .foregroundStyle(Theme.label)

                                if let notes = area.notes, !notes.isEmpty {
                                    Text(notes)
                                        .font(Theme.fontFootnote)
                                        .foregroundStyle(Theme.secondaryLabel)
                                        .lineLimit(2)
                                }
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Theme.tertiaryLabel)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        AppRouter.shared.navigateToAreaEditor(area: area, report: report)
                    }
                }
            } else {
                Text("No areas added yet.")
                    .font(Theme.fontCallout)
                    .foregroundStyle(Theme.secondaryLabel)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(Theme.spacingL)
            }
        }
    }

    // MARK: - Issues Section

    private func issuesSection(_ report: InspectionReport) -> some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            SSSectionHeader(
                "Issues",
                actionTitle: "Add",
                actionIcon: "plus",
                action: {
                    AppRouter.shared.navigateToIssueEditor(issue: nil, area: nil, report: report)
                }
            )

            if let issues = report.issues, !issues.isEmpty {
                ForEach(issues) { issue in
                    SSCard(padding: Theme.spacingM) {
                        VStack(alignment: .leading, spacing: Theme.spacingS) {
                            HStack {
                                Text(issue.title)
                                    .font(Theme.fontHeadline)
                                    .foregroundStyle(Theme.label)
                                    .lineLimit(1)

                                Spacer()

                                StatusDot(color: issue.status.color, size: 8)
                            }

                            if let area = issue.area {
                                Text(area.name)
                                    .font(Theme.fontFootnote)
                                    .foregroundStyle(Theme.secondaryLabel)
                            }

                            HStack(spacing: Theme.spacingS) {
                                SeverityIndicator(severity: issue.severity, showLabel: true)

                                Spacer()

                                if let photos = issue.photos {
                                    Label("\(photos.count)", systemImage: "photo")
                                        .font(Theme.fontCaption)
                                        .foregroundStyle(Theme.secondaryLabel)
                                }
                            }
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        AppRouter.shared.navigateToIssueEditor(issue: issue, area: issue.area, report: report)
                    }
                }
            } else {
                Text("No issues recorded yet.")
                    .font(Theme.fontCallout)
                    .foregroundStyle(Theme.secondaryLabel)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(Theme.spacingL)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    MainTabView()
        .modelContainer(for: [
            UserProfile.self,
            InspectionReport.self,
            InspectionArea.self,
            InspectionIssue.self,
            IssuePhoto.self
        ])
}
