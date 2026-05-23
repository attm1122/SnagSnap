// SnagSnap
// ReportWorkspaceView.swift
//
// Main workspace container with segmented tab picker for Overview, Areas,
// Issues, and Report tabs.

import SwiftUI
import SwiftData

// MARK: - ReportWorkspaceView

/// The main workspace view for managing a single inspection report.
/// Provides a segmented tab interface switching between Overview, Areas, Issues, and Report tabs.
struct ReportWorkspaceView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Environment(AppRouter.self) private var router
    @State private var viewModel = ReportWorkspaceViewModel()
    @State private var hasAppliedInitialTab = false
    @State private var hasPerformedLaunchAction = false

    // MARK: - Report

    let report: InspectionReport
    private let initialTab: WorkspaceTab
    private let launchAction: WorkspaceLaunchAction

    init(
        report: InspectionReport,
        initialTab: WorkspaceTab = .overview,
        launchAction: WorkspaceLaunchAction = .none
    ) {
        self.report = report
        self.initialTab = initialTab
        self.launchAction = launchAction
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: Theme.spacingM) {
            // Segmented tab picker
            Picker("Tab", selection: $viewModel.selectedTab) {
                ForEach(WorkspaceTab.allCases) { tab in
                    Label(tab.rawValue, systemImage: tab.icon)
                        .tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(5)
            .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: Theme.radiusLarge, style: .continuous))
            .padding(.horizontal, Theme.spacingL)
            .padding(.top, Theme.spacingM)
            .onChange(of: viewModel.selectedTab) { _, _ in
                HapticService.shared.play(.selection)
            }

            // Tab content
            ScrollView {
                Group {
                    switch viewModel.selectedTab {
                    case .overview:
                        OverviewTabView(report: report, viewModel: viewModel)

                    case .areas:
                        AreasTabView(report: report, viewModel: viewModel)

                    case .issues:
                        IssuesTabView(report: report, viewModel: viewModel)

                    case .report:
                        ReportTabView(report: report, viewModel: viewModel)
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: viewModel.selectedTab)
            }
            .scrollIndicators(.hidden)
        }
        .background(
            LinearGradient(
                colors: [Theme.blueSurfaceStrong, Theme.background, Theme.background],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .navigationTitle(report.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.blueSurfaceStrong, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        viewModel.showEditSheet = true
                    } label: {
                        Label("Edit Report", systemImage: "pencil")
                    }

                    Button {
                        shareReport()
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                        .foregroundStyle(Theme.ink)
                }
            }
        }
        .sheet(isPresented: $viewModel.showEditSheet) {
            EditReportSheet(report: report)
        }
        .sheet(isPresented: parentAddAreaSheetBinding) {
            AddEditAreaView(report: report)
        }
        .onAppear {
            if !hasAppliedInitialTab {
                viewModel.selectedTab = initialTab
                hasAppliedInitialTab = true
            }
            performLaunchActionIfNeeded()
        }
        .animateOnAppear(delay: 0.05, duration: 0.4)
    }

    // MARK: - Actions

    private func shareReport() {
        viewModel.generatePDF(for: report, modelContext: modelContext)
        viewModel.prepareShare()
    }

    private var parentAddAreaSheetBinding: Binding<Bool> {
        Binding(
            get: { viewModel.showAddAreaSheet && viewModel.selectedTab != .areas },
            set: { isPresented in
                if !isPresented {
                    viewModel.showAddAreaSheet = false
                }
            }
        )
    }

    private func performLaunchActionIfNeeded() {
        guard !hasPerformedLaunchAction else { return }
        hasPerformedLaunchAction = true

        switch launchAction {
        case .none:
            return
        case .addArea:
            DispatchQueue.main.async {
                viewModel.showAddAreaSheet = true
            }
        case .addIssue:
            DispatchQueue.main.async {
                let area = firstAreaOrCreateGeneralArea()
                router.navigateToIssueEditor(issue: nil, area: area, report: report)
            }
        }
    }

    private func firstAreaOrCreateGeneralArea() -> InspectionArea {
        if let firstArea = report.areas?.first {
            return firstArea
        }

        let area = InspectionArea(name: "General")
        modelContext.insert(area)
        area.report = report

        if report.areas == nil {
            report.areas = []
        }
        report.areas?.append(area)
        report.updatedAt = Date()
        try? modelContext.save()
        return area
    }
}

// MARK: - Edit Report Sheet

private struct EditReportSheet: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let report: InspectionReport

    @State private var title: String = ""
    @State private var propertyName: String = ""
    @State private var propertyAddress: String = ""
    @State private var clientName: String = ""
    @State private var inspectorName: String = ""
    @State private var generalNotes: String = ""
    @State private var inspectionDate: Date = Date()
    @State private var reportType: ReportType = .general

    var body: some View {
        NavigationStack {
            Form {
                Section("Report Details") {
                    TextField("Title", text: $title)
                        .autocorrectionDisabled()
                    TextField("Property Name", text: $propertyName)
                        .autocorrectionDisabled()
                    TextField("Property Address", text: $propertyAddress, axis: .vertical)
                    DatePicker("Inspection Date", selection: $inspectionDate, displayedComponents: .date)
                }

                Section("Report Type") {
                    Picker("Type", selection: $reportType) {
                        ForEach(ReportType.allCases) { type in
                            Label(type.displayName, systemImage: type.icon).tag(type)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }

                Section("Optional Details") {
                    TextField("Client / Tenant Name", text: $clientName)
                    TextField("Inspector Name", text: $inspectorName)
                        .autocorrectionDisabled()
                }

                Section("General Notes") {
                    TextEditor(text: $generalNotes)
                        .frame(minHeight: 100)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background.ignoresSafeArea())
            .tint(Theme.primary)
            .navigationTitle("Edit Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.background, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.primary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Theme.primary)
                }
            }
            .onAppear {
                title = report.title
                propertyName = report.propertyName
                propertyAddress = report.propertyAddress
                clientName = report.clientName ?? ""
                inspectorName = report.inspectorName ?? ""
                generalNotes = report.generalNotes ?? ""
                inspectionDate = report.inspectionDate
                reportType = report.reportType
            }
        }
    }

    private func save() {
        report.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        report.propertyName = propertyName.trimmingCharacters(in: .whitespacesAndNewlines)
        report.propertyAddress = propertyAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        report.clientName = clientName.isEmpty ? nil : clientName.trimmingCharacters(in: .whitespacesAndNewlines)
        report.inspectorName = inspectorName.isEmpty ? nil : inspectorName.trimmingCharacters(in: .whitespacesAndNewlines)
        report.generalNotes = generalNotes.isEmpty ? nil : generalNotes.trimmingCharacters(in: .whitespacesAndNewlines)
        report.inspectionDate = inspectionDate
        report.reportType = reportType
        report.updatedAt = Date()

        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Preview

#Preview("Report Workspace") {
    let schema = Schema([InspectionReport.self, InspectionArea.self, InspectionIssue.self, IssuePhoto.self])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [config])
    let context = ModelContext(container)

    let report = InspectionReport(
        title: "15 Oak Avenue - Move In",
        propertyName: "15 Oak Avenue",
        propertyAddress: "15 Oak Avenue, Manchester M1 1AA",
        reportType: .moveIn,
        clientName: "Sarah Johnson",
        inspectorName: "Mike Thompson",
        generalNotes: "Standard move-in inspection. Tenant present during inspection."
    )
    context.insert(report)

    let kitchen = InspectionArea(name: "Kitchen", notes: "Modern fitted kitchen")
    context.insert(kitchen)
    kitchen.report = report
    report.areas = [kitchen]

    let bathroom = InspectionArea(name: "Bathroom", notes: "Family bathroom with shower over bath")
    context.insert(bathroom)
    bathroom.report = report
    report.areas?.append(bathroom)

    let issue1 = InspectionIssue(title: "Cracked tile near sink", notes: "Visible crack in ceramic tile", severity: .high, status: .open)
    context.insert(issue1)
    issue1.report = report
    issue1.area = kitchen

    let issue2 = InspectionIssue(title: "Loose door handle", severity: .low, status: .fixed)
    context.insert(issue2)
    issue2.report = report
    issue2.area = bathroom

    let issue3 = InspectionIssue(title: "Water stain on ceiling", notes: "Discoloration indicating possible leak", severity: .urgent, status: .open)
    context.insert(issue3)
    issue3.report = report
    issue3.area = kitchen

    report.issues = [issue1, issue2, issue3]
    try? context.save()

    return NavigationStack {
        ReportWorkspaceView(report: report)
    }
    .modelContainer(container)
    .environment(AppRouter.shared)
}
