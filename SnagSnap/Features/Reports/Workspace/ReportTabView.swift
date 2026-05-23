// SnagSnap
// ReportTabView.swift
//
// Report generation tab with export settings, staged PDF generation,
// success/error states, and intelligent sharing prompts.

import SwiftUI
import SwiftData

// MARK: - ReportTabView

/// Provides PDF export settings, staged generation controls with progress,
/// success/error states, and intelligent sharing options for the inspection report.
struct ReportTabView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme

    let report: InspectionReport
    @Bindable var viewModel: ReportWorkspaceViewModel

    @State private var showRegenerateConfirm = false
    @State private var showPDFPreview = false
    @State private var previewPDFData: Data?

    // MARK: - Body

    var body: some View {
        ZStack {
            // MARK: Normal Content
            normalContent
                .opacity(normalContentOpacity)

            // MARK: Success State
            if case .success(let data) = viewModel.pdfState {
                SuccessStateView(
                    title: "PDF Ready",
                    message: "Your report has been generated and saved.",
                    primaryAction: .init(
                        title: "Share Report",
                        icon: "square.and.arrow.up",
                        handler: {
                            viewModel.sharePDFData(data, reportTitle: report.title)
                        }
                    ),
                    secondaryAction: .init(
                        title: "Preview PDF",
                        icon: "doc.text",
                        handler: {
                            previewPDFData = data
                            showPDFPreview = true
                        }
                    ),
                    tertiaryAction: .init(
                        title: "Done",
                        icon: nil,
                        handler: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                viewModel.resetPDFState()
                            }
                        }
                    )
                )
                .transition(.opacity.combined(with: .scale(scale: 0.96)).animation(.easeInOut(duration: 0.35)))
                .zIndex(1)
            }

            // MARK: Error State
            if case .failed(let error) = viewModel.pdfState {
                ErrorStateView(
                    title: "Could not generate PDF",
                    message: error.localizedDescription,
                    retryAction: {
                        HapticService.shared.play(.medium)
                        viewModel.generatePDF(for: report, modelContext: modelContext)
                    },
                    dismissAction: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            viewModel.resetPDFState()
                        }
                    }
                )
                .transition(.opacity.combined(with: .move(edge: .bottom)).animation(.easeInOut(duration: 0.35)))
                .zIndex(1)
            }
        }
        .stagedLoadingOverlay(
            isPresented: viewModel.pdfState.isGenerating,
            stages: PDFGenerationStage.allLabels,
            currentStage: viewModel.pdfState.currentStageIndex,
            title: "Building your report..."
        )
        .alert("Report Changed", isPresented: $viewModel.showSharePrompt) {
            Button("Re-generate First", role: .none) {
                viewModel.generatePDF(for: report, modelContext: modelContext)
            }
            Button("Share Existing", role: .none) {
                viewModel.shareLatestPDF(for: report)
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This report has changes since the last PDF export. Regenerate before sharing?")
        }
        .confirmationDialog(
            "Re-generate PDF?",
            isPresented: $showRegenerateConfirm,
            titleVisibility: .visible
        ) {
            Button("Re-generate", role: .destructive) {
                HapticService.shared.play(.medium)
                viewModel.resetPDFState()
                // Small delay to let the state reset animate
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    viewModel.generatePDF(for: report, modelContext: modelContext)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("A PDF already exists. Re-generating will overwrite it.")
        }
        .sheet(isPresented: $showPDFPreview) {
            if let data = previewPDFData {
                PDFPreviewView(report: report, pdfData: data)
            }
        }
        .onAppear {
            viewModel.checkForExistingPDF(for: report)
        }
    }

    // MARK: - Normal Content Opacity

    private var normalContentOpacity: Double {
        switch viewModel.pdfState {
        case .idle, .generating:
            return 1.0
        case .success, .failed:
            return 0.0
        }
    }

    // MARK: - Normal Content

    private var normalContent: some View {
        ScrollView {
            VStack(spacing: Theme.spacingL) {
                // Summary card
                summaryCard
                    .animateOnAppear(delay: 0, duration: 0.45)

                // PDF status section (if a PDF has been exported)
                if report.hasExportedPDF {
                    pdfStatusSection
                        .animateOnAppear(delay: 0.05, duration: 0.45)
                }

                // Export settings
                exportSettingsSection
                    .animateOnAppear(delay: 0.1, duration: 0.45)

                // PDF watermark notice for free users
                if EntitlementManager.shared.shouldShowWatermark {
                    watermarkNotice
                        .animateOnAppear(delay: 0.15, duration: 0.45)
                }

                // Generate / action buttons
                actionButtons
                    .animateOnAppear(delay: 0.2, duration: 0.45)

                Spacer(minLength: Theme.spacingXXL)
            }
            .padding(Theme.spacingM)
        }
        .background(Theme.groupedBackground.ignoresSafeArea())
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        SSCard(padding: Theme.spacingL, cornerRadius: Theme.radiusLarge) {
            VStack(alignment: .leading, spacing: Theme.spacingM) {
                HStack {
                    Image(systemName: "doc.fill")
                        .font(.title2)
                        .foregroundStyle(Theme.primary)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Report Summary")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.primary)

                        Text(report.summaryDescription)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }

                    Spacer()
                }

                Divider()

                HStack(spacing: Theme.spacingXL) {
                    summaryItem(value: "\(report.areaCount)", label: "Areas")
                    summaryItem(value: "\(report.issueCount)", label: "Issues")
                    summaryItem(value: "\(report.photoCount)", label: "Photos")
                }

                if report.isComplete {
                    HStack {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(Theme.success)
                        Text("Report is ready to export")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Theme.success)
                    }
                    .padding(.top, Theme.spacingS)
                }
            }
        }
    }

    // MARK: - PDF Status Section

    private var pdfStatusSection: some View {
        SSCard(padding: Theme.spacingL, cornerRadius: Theme.radiusLarge) {
            VStack(alignment: .leading, spacing: Theme.spacingM) {
                HStack {
                    Image(systemName: "doc.fill")
                        .font(.title2)
                        .foregroundStyle(Theme.success)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("PDF Ready")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.primary)

                        if let display = report.lastExportedDisplay {
                            Text("Exported \(display)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        if let path = report.latestPDFPath,
                           let fileSize = FileStorageService.shared.pdfFileSize(named: path) {
                            Text(fileSize)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()
                }

                Divider()

                HStack(spacing: Theme.spacingM) {
                    SSButton(
                        "Share",
                        style: .primary,
                        icon: "square.and.arrow.up",
                        isFullWidth: true
                    ) {
                        HapticService.shared.play(.medium)
                        if viewModel.canShareWithoutRegenerating(report: report) {
                            viewModel.shareLatestPDF(for: report)
                        } else {
                            viewModel.showSharePrompt = true
                        }
                    }
                    .accessibilityLabel("Share PDF report")

                    SSButton(
                        "Re-generate",
                        style: .secondary,
                        icon: "arrow.clockwise",
                        isFullWidth: true
                    ) {
                        showRegenerateConfirm = true
                    }
                }
            }
        }
    }

    // MARK: - Export Settings Section

    private var exportSettingsSection: some View {
        SSCard(padding: Theme.spacingL, cornerRadius: Theme.radiusLarge) {
            VStack(alignment: .leading, spacing: Theme.spacingM) {
                SSSectionHeader("Export Settings")

                VStack(spacing: 0) {
                    Toggle("Include Cover Page", isOn: $viewModel.exportSettings.includeCoverPage)
                        .font(.body)

                    Divider()
                        .padding(.vertical, Theme.spacingS)

                    Toggle("Include Summary", isOn: $viewModel.exportSettings.includeSummary)
                        .font(.body)

                    Divider()
                        .padding(.vertical, Theme.spacingS)

                    Toggle("Include Photos", isOn: $viewModel.exportSettings.includePhotos)
                        .font(.body)

                    Divider()
                        .padding(.vertical, Theme.spacingS)

                    Toggle("Include Issue Statuses", isOn: $viewModel.exportSettings.includeIssueStatuses)
                        .font(.body)

                    Divider()
                        .padding(.vertical, Theme.spacingS)

                    Toggle("Include Inspector Details", isOn: $viewModel.exportSettings.includeInspectorDetails)
                        .font(.body)

                    Divider()
                        .padding(.vertical, Theme.spacingS)

                    Toggle("Include Timestamps", isOn: $viewModel.exportSettings.includeTimestamps)
                        .font(.body)

                    if EntitlementManager.shared.canAccessProFeature() {
                        Divider()
                            .padding(.vertical, Theme.spacingS)

                        Toggle("Include Watermark", isOn: $viewModel.exportSettings.includeWatermark)
                            .font(.body)
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: Theme.primary))
            }
        }
    }

    // MARK: - Watermark Notice

    private var watermarkNotice: some View {
        HStack(spacing: Theme.spacingS) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(.secondary)

            Text("Free-tier PDF exports include a SnagSnap watermark. Upgrade to Pro for watermark-free exports.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(Theme.spacingM)
        .background(Color.gray.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMedium, style: .continuous))
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: Theme.spacingM) {
            if report.hasExportedPDF {
                // PDF exists from a previous session
                SSButton(
                    "Re-generate PDF Report",
                    style: .secondary,
                    icon: "arrow.clockwise",
                    isLoading: viewModel.isGeneratingPDF,
                    isFullWidth: true
                ) {
                    showRegenerateConfirm = true
                }
                .accessibilityLabel("Re-generate PDF report")
            } else {
                // No PDF exists yet
                SSButton(
                    "Generate PDF Report",
                    style: .primary,
                    icon: "doc.badge.gearshape",
                    isLoading: viewModel.isGeneratingPDF,
                    isFullWidth: true
                ) {
                    HapticService.shared.play(.medium)
                    viewModel.generatePDF(for: report, modelContext: modelContext)
                }
                .accessibilityLabel("Generate PDF report")
            }
        }
    }

    // MARK: - Helper Views

    private func summaryItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(.primary)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview("Report Tab") {
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
        inspectorName: "Mike Thompson"
    )
    context.insert(report)

    let kitchen = InspectionArea(name: "Kitchen")
    context.insert(kitchen)
    kitchen.report = report
    report.areas = [kitchen]

    let issue1 = InspectionIssue(
        title: "Cracked tile near sink",
        notes: "Visible crack in ceramic tile next to sink. Water may seep through.",
        severity: .high,
        status: .open
    )
    context.insert(issue1)
    issue1.report = report
    issue1.area = kitchen

    let issue2 = InspectionIssue(
        title: "Loose cabinet handle",
        notes: "Handle on upper cabinet is loose and wobbles.",
        severity: .low,
        status: .fixed
    )
    context.insert(issue2)
    issue2.report = report
    issue2.area = kitchen

    report.issues = [issue1, issue2]
    try? context.save()

    let viewModel = ReportWorkspaceViewModel()

    return ReportTabView(report: report, viewModel: viewModel)
        .modelContainer(container)
}
