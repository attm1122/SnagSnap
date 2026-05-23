import SwiftUI
import SwiftData

// MARK: - Route

/// Navigation routes used throughout the app.
///
/// Uses UUID-based identifiers for SwiftData models to ensure proper Hashable
/// conformance. Destination views are responsible for fetching models from
/// the model context using these identifiers.
enum Route: Hashable {
    /// Create a new inspection report
    case createReport(targetTab: WorkspaceTab, launchAction: WorkspaceLaunchAction)

    /// Navigate to a report's workspace/editor
    case reportWorkspace(reportID: UUID, initialTab: WorkspaceTab, launchAction: WorkspaceLaunchAction)

    /// Open the issue editor (nil issue = new issue)
    case issueEditor(issueID: UUID?, areaID: UUID?, reportID: UUID)

    /// Open the area editor (nil area = new area)
    case areaEditor(areaID: UUID?, reportID: UUID)

    /// Open photo annotation view
    case photoAnnotation(photoID: UUID)

    /// Preview generated PDF
    case pdfPreview(reportID: UUID)

    /// Show paywall/upgrade screen
    case paywall

    /// Navigate to settings
    case settings

    // MARK: Convenience initializers with model objects

    static func reportWorkspace(
        _ report: InspectionReport,
        initialTab: WorkspaceTab = .overview,
        launchAction: WorkspaceLaunchAction = .none
    ) -> Route {
        .reportWorkspace(reportID: report.id, initialTab: initialTab, launchAction: launchAction)
    }

    static func issueEditor(issue: InspectionIssue?, area: InspectionArea?, report: InspectionReport) -> Route {
        .issueEditor(issueID: issue?.id, areaID: area?.id, reportID: report.id)
    }

    static func areaEditor(area: InspectionArea?, report: InspectionReport) -> Route {
        .areaEditor(areaID: area?.id, reportID: report.id)
    }

    static func photoAnnotation(_ photo: IssuePhoto) -> Route {
        .photoAnnotation(photoID: photo.id)
    }

    static func pdfPreview(_ report: InspectionReport) -> Route {
        .pdfPreview(reportID: report.id)
    }
}

// MARK: - AppRouter

/// Central navigation router managing all app navigation state.
///
/// Uses the `@Observable` macro (iOS 17+) for fine-grained observation.
/// Manages separate NavigationPath instances for each tab to preserve
/// navigation state when switching between tabs.
@Observable
final class AppRouter {
    static let shared = AppRouter()

    /// Navigation path for the Home tab
    var homePath = NavigationPath()

    /// Navigation path for the Settings tab
    var settingsPath = NavigationPath()

    /// Currently selected tab
    var selectedTab: Tab = .home

    /// Private initializer for singleton
    private init() {}

    // MARK: - Tab Definitions

    enum Tab: String, CaseIterable, Identifiable {
        case home
        case settings

        var id: String { rawValue }

        var title: String {
            switch self {
            case .home: return "Home"
            case .settings: return "Settings"
            }
        }

        var icon: String {
            switch self {
            case .home: return Theme.iconHome
            case .settings: return Theme.iconSettings
            }
        }
    }

    // MARK: - Navigation Actions (Home Tab)

    /// Navigate to a report workspace
    func navigateToReport(
        _ report: InspectionReport,
        initialTab: WorkspaceTab = .overview,
        launchAction: WorkspaceLaunchAction = .none
    ) {
        homePath.append(Route.reportWorkspace(report, initialTab: initialTab, launchAction: launchAction))
    }

    /// Navigate to report creation
    func navigateToCreateReport(
        targetTab: WorkspaceTab = .overview,
        launchAction: WorkspaceLaunchAction = .none
    ) {
        homePath.append(Route.createReport(targetTab: targetTab, launchAction: launchAction))
    }

    /// Replace the current home route with a new route.
    func replaceCurrentHomeRoute(with route: Route) {
        if !homePath.isEmpty {
            homePath.removeLast()
        }
        homePath.append(route)
    }

    /// Navigate to issue editor
    func navigateToIssueEditor(issue: InspectionIssue?, area: InspectionArea?, report: InspectionReport) {
        homePath.append(Route.issueEditor(issue: issue, area: area, report: report))
    }

    /// Navigate to area editor
    func navigateToAreaEditor(area: InspectionArea?, report: InspectionReport) {
        homePath.append(Route.areaEditor(area: area, report: report))
    }

    /// Navigate to photo annotation
    func navigateToPhotoAnnotation(_ photo: IssuePhoto) {
        homePath.append(Route.photoAnnotation(photo))
    }

    /// Navigate to PDF preview
    func navigateToPDFPreview(report: InspectionReport) {
        homePath.append(Route.pdfPreview(report))
    }

    // MARK: - Navigation Actions (Settings Tab)

    /// Navigate to paywall
    func navigateToPaywall() {
        settingsPath.append(Route.paywall)
    }

    // MARK: - Back Navigation

    /// Go back one step on the active path
    func goBack() {
        switch selectedTab {
        case .home:
            if !homePath.isEmpty {
                homePath.removeLast()
            }
        case .settings:
            if !settingsPath.isEmpty {
                settingsPath.removeLast()
            }
        }
    }

    /// Go back one step on a specific path
    func goBack(on tab: Tab) {
        switch tab {
        case .home:
            if !homePath.isEmpty {
                homePath.removeLast()
            }
        case .settings:
            if !settingsPath.isEmpty {
                settingsPath.removeLast()
            }
        }
    }

    // MARK: - Root Navigation

    /// Pop to root on the active path
    func popToRoot() {
        switch selectedTab {
        case .home:
            homePath.removeLast(homePath.count)
        case .settings:
            settingsPath.removeLast(settingsPath.count)
        }
    }

    /// Pop to root on a specific path
    func popToRoot(on tab: Tab) {
        switch tab {
        case .home:
            homePath.removeLast(homePath.count)
        case .settings:
            settingsPath.removeLast(settingsPath.count)
        }
    }

    /// Pop to root on all paths and reset to home tab
    func resetToRoot() {
        homePath.removeLast(homePath.count)
        settingsPath.removeLast(settingsPath.count)
        selectedTab = .home
    }

    // MARK: - Model Fetching Helpers

    /// Fetch a model by ID from the model context (to be used in destination views)
    static func fetchReport(id: UUID, context: ModelContext) -> InspectionReport? {
        let descriptor = FetchDescriptor<InspectionReport>(
            predicate: #Predicate { $0.id == id }
        )
        return try? context.fetch(descriptor).first
    }

    static func fetchArea(id: UUID, context: ModelContext) -> InspectionArea? {
        let descriptor = FetchDescriptor<InspectionArea>(
            predicate: #Predicate { $0.id == id }
        )
        return try? context.fetch(descriptor).first
    }

    static func fetchIssue(id: UUID, context: ModelContext) -> InspectionIssue? {
        let descriptor = FetchDescriptor<InspectionIssue>(
            predicate: #Predicate { $0.id == id }
        )
        return try? context.fetch(descriptor).first
    }

    static func fetchPhoto(id: UUID, context: ModelContext) -> IssuePhoto? {
        let descriptor = FetchDescriptor<IssuePhoto>(
            predicate: #Predicate { $0.id == id }
        )
        return try? context.fetch(descriptor).first
    }
}
