// SnagSnap
// MainTabView.swift
//
// Root tab view with Home and Settings tabs, each with NavigationStack routing.

import SwiftUI
import SwiftData

// MARK: - MainTabView

/// The root tab view for the SnagSnap app.
///
/// Provides two tabs -- Home and Settings -- each wrapped in a `NavigationStack`
/// with route-based navigation. Uses the shared `AppRouter` for all navigation state.
struct MainTabView: View {

    @State private var router = AppRouter.shared
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        TabView(selection: $router.selectedTab) {
            // MARK: Home Tab
            NavigationStack(path: $router.homePath) {
                HomeDashboardView()
                    .navigationDestination(for: Route.self) { route in
                        homeRouteDestination(for: route)
                    }
            }
            .tabItem {
                Label(AppRouter.Tab.home.title, systemImage: AppRouter.Tab.home.icon)
            }
            .tag(AppRouter.Tab.home)

            // MARK: Settings Tab
            NavigationStack(path: $router.settingsPath) {
                SettingsView(viewModel: SettingsViewModel(modelContext: modelContext))
                    .navigationDestination(for: Route.self) { route in
                        settingsRouteDestination(for: route)
                    }
            }
            .tabItem {
                Label(AppRouter.Tab.settings.title, systemImage: AppRouter.Tab.settings.icon)
            }
            .tag(AppRouter.Tab.settings)
        }
        .tint(Theme.primary)
        .environment(router)
        .toolbarBackground(Theme.cardBackground, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .onChange(of: router.selectedTab) { _, _ in
            HapticService.shared.play(.selection)
        }
    }

    // MARK: - Home Route Destinations

    @ViewBuilder
    private func homeRouteDestination(for route: Route) -> some View {
        switch route {
        case .createReport(let targetTab, let launchAction):
            CreateReportView(
                modelContext: modelContext,
                onComplete: { report in
                    router.completeCreateReport(
                        report,
                        targetTab: targetTab,
                        launchAction: launchAction
                    )
                }
            )

        case .reportWorkspace(let reportID, let initialTab, let launchAction):
            if let report = AppRouter.fetchReport(id: reportID, context: modelContext) {
                ReportWorkspaceView(report: report, initialTab: initialTab, launchAction: launchAction)
            } else {
                errorView(message: "Report not found")
            }

        case .issueEditor(let issueID, let areaID, let reportID):
            if let report = AppRouter.fetchReport(id: reportID, context: modelContext) {
                let issue = issueID.flatMap { AppRouter.fetchIssue(id: $0, context: modelContext) }
                let area = areaID.flatMap { AppRouter.fetchArea(id: $0, context: modelContext) }
                CreateEditIssueView(
                    issue: issue,
                    area: area,
                    report: report,
                    modelContext: modelContext,
                    onComplete: { router.goBack() }
                )
            } else {
                errorView(message: "Report not found")
            }

        case .areaEditor(let areaID, let reportID):
            if let report = AppRouter.fetchReport(id: reportID, context: modelContext) {
                let area = areaID.flatMap { AppRouter.fetchArea(id: $0, context: modelContext) }
                AddEditAreaView(area: area, report: report)
            } else {
                errorView(message: "Report not found")
            }

        case .photoAnnotation(let photoID):
            if let photo = AppRouter.fetchPhoto(id: photoID, context: modelContext) {
                PhotoAnnotationView(photo: photo)
            } else {
                errorView(message: "Photo not found")
            }

        case .pdfPreview(let reportID):
            if let report = AppRouter.fetchReport(id: reportID, context: modelContext) {
                PDFPreviewView(report: report)
            } else {
                errorView(message: "Report not found")
            }

        case .paywall:
            PaywallView()

        case .settings:
            SettingsView(viewModel: SettingsViewModel(modelContext: modelContext))
        }
    }

    // MARK: - Settings Route Destinations

    @ViewBuilder
    private func settingsRouteDestination(for route: Route) -> some View {
        switch route {
        case .paywall:
            PaywallView()
        default:
            errorView(message: "Navigation not available from settings")
        }
    }

    // MARK: - Error View

    private func errorView(message: String) -> some View {
        VStack(spacing: Theme.spacingL) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(Theme.warning)

            Text("Oops!")
                .font(Theme.title)

            Text(message)
                .font(Theme.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            SSButton(title: "Go Back", style: .secondary) {
                router.goBack()
            }
        }
        .padding(Theme.spacingXL)
        .navigationTitle("Error")
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
