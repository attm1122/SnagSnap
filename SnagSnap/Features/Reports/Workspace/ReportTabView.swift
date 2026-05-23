// SnagSnap
// ReportTabView.swift
//
// Report generation tab with export settings, PDF generation,
// and sharing functionality.

import SwiftUI
import SwiftData

// MARK: - ReportTabView

/// Provides PDF export settings, generation controls, and sharing options
/// for the inspection report.
struct ReportTabView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme

    let report: InspectionReport
    let viewModel: ReportWorkspaceViewModel
    @State private var showPDFGeneratedToast = false
    @State private var showRegenerateConfirm = false

    // MARK: - Body

    var body: some View {
        VStack(spacing: Theme.spacingL) {
            // Summary card
            summaryCard

            // PDF status section (if a PDF has been exported)
            if report.hasExportedPDF {
                pdfStatusSection
            }

            // Export settings
            exportSettingsSection

            // PDF watermark notice for free users
            if EntitlementManager.shared.shouldShowWatermark {
                watermarkNotice
            }

            // Generate / Share buttons
            actionButtons

            // Error display
            if case .error(let message) = viewModel.pdfState {
                errorView(message: message)
            }

            Spacer(minLength: 0)
        }
        .padding(Theme.spacingM)
        .onAppear {
            viewModel.checkForExistingPDF(for: report)
        }
        .onChange(of: viewModel.pdfState) { _, newState in
            if case .generated = newState {
                HapticService.shared.play(.success)
            }
        }
        .confirmationDialog(
            "Re-generate PDF?",
            isPresented: $showRegenerateConfirm,
            titleVisibility: .visible
        ) {
            Button("Re-generate", role: .destructive) {
                HapticService.shared.play(.medium)
                viewModel.resetPDFState()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("A PDF already exists. Re-generating will overwrite it.")
        }
        .sheet(isPresented: $viewModel.showShareSheet) {
            if let data = viewModel.pdfDataToShare {
                ShareSheet(activityItems: [data])
            }
        }
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
                        "Re-generate PDF",
                        style: .secondary,
                        icon: "arrow.clockwise",
                        isFullWidth: true
                    ) {
                        showRegenerateConfirm = true
                    }

                    SSButton(
                        "Share PDF",
                        style: .primary,
                        icon: "square.and.arrow.up",
                        isFullWidth: true
                    ) {
                        HapticService.shared.play(.medium)
                        viewModel.shareLatestPDF(for: report)
                    }
                    .accessibilityLabel("Share PDF report")
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
            if viewModel.canSharePDF {
                // PDF was just generated in this session — show share + re-generate
                SSButton(
                    "Share PDF",
                    style: .primary,
                    icon: "square.and.arrow.up",
                    isFullWidth: true
                ) {
                    HapticService.shared.play(.medium)
                    viewModel.prepareShare()
                }
                .accessibilityLabel("Share PDF report")

                SSButton(
                    "Re-generate PDF Report",
                    style: .secondary,
                    icon: "arrow.clockwise",
                    isFullWidth: true
                ) {
                    showRegenerateConfirm = true
                }
            } else if report.hasExportedPDF {
                // PDF exists from a previous session — show re-generate primary
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

    // MARK: - Error View

    private func errorView(message: String) -> some View {
        HStack(spacing: Theme.spacingS) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Theme.error)

            Text("PDF generation failed: \(message)")
                .font(.subheadline)
                .foregroundStyle(Theme.error)

            Spacer()
        }
        .padding(Theme.spacingM)
        .background(Theme.error.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMedium, style: .continuous))
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

// MARK: - Share Sheet

/// UIKit share sheet wrapper for SwiftUI.
private struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
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
        report