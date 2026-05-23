import SwiftUI

struct MainTabView: View {
    @State private var router = AppRouter.shared

    var body: some View {
        TabView(selection: $router.selectedTab) {
            NavigationStack(path: $router.homePath) {
                HomeView()
                    .navigationDestination(for: Route.self) { route in
                        routeDestination(for: route)
                    }
            }
            .tabItem {
                Label(AppRouter.Tab.home.title, systemImage: AppRouter.Tab.home.icon)
            }
            .tag(AppRouter.Tab.home)

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
    }

    @ViewBuilder
    private func routeDestination(for route: Route) -> some View {
        switch route {
        case .createReport:
            Text("Create Report")
                .navigationTitle("New Report")

        case .reportWorkspace(let report):
            Text("Report: \(report.title)")
                .navigationTitle(report.title)

        case .issueEditor(let issue, let area, let report):
            Text("Issue Editor: \(issue?.title ?? "New Issue")")
                .navigationTitle(issue == nil ? "New Issue" : "Edit Issue")

        case .areaEditor(let area, let report):
            Text("Area Editor: \(area?.name ?? "New Area")")
                .navigationTitle(area == nil ? "New Area" : "Edit Area")

        case .photoAnnotation(let photo):
            Text("Photo Annotation: \(photo.id.uuidString.prefix(8))")
                .navigationTitle("Annotate Photo")

        case .pdfPreview(let report):
            Text("PDF Preview: \(report.title)")
                .navigationTitle("PDF Preview")

        case .paywall:
            Text("Paywall")
                .navigationTitle("Upgrade")

        case .settings:
            SettingsView()
        }
    }
}

struct HomeView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: Theme.spacingM) {
                Text("Welcome to SnagSnap")
                    .font(Theme.fontLargeTitle)
                    .foregroundStyle(Theme.label)

                Button("Create Report") {
                    AppRouter.shared.navigateToCreateReport()
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .padding(Theme.spacingM)
        }
        .background(Theme.groupedBackground)
        .navigationTitle("Home")
    }
}

struct SettingsView: View {
    var body: some View {
        List {
            Section("Account") {
                NavigationLink(value: Route.paywall) {
                    Label("Upgrade to Pro", systemImage: Theme.iconStar)
                }
            }
        }
        .navigationTitle("Settings")
    }
}

#Preview {
    MainTabView()
}
