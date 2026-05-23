// SnagSnap
// PDFPreviewView.swift
//
// PDF preview using PDFKit with share functionality and dismiss support.

import SwiftUI
import SwiftData
import PDFKit

// MARK: - PDFPreviewView

/// Displays a generated PDF report using PDFKit's native PDFView,
/// with toolbar controls for sharing and dismissal.
struct PDFPreviewView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Properties

    let report: InspectionReport

    // MARK: - Local State

    @State private var pdfDocument: PDFDocument?
    @State private var isGenerating = true
    @State private var errorMessage: String?
    @State private var showShareSheet = false
    @State private var pdfDataToShare: Data?

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.groupedBackground.ignoresSafeArea()

                if isGenerating {
                    loadingView
                } else if let errorMessage = errorMessage {
                    errorView(message: errorMessage)
                } else if let pdfDocument = pdfDocument {
                    pdfKitView(document: pdfDocument)
                } else {
                    emptyView
                }
            }
            .navigationTitle(report.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(Theme.primary)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: Theme.spacingM) {
                        if pdfDocument != nil {
                            Button {
                                pdfDataToShare = pdfDocument?.dataRepresentation()
                                showShareSheet = true
                            } label: {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.body.weight(.medium))
                            }
                            .foregroundStyle(Theme.primary)
                        }
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let data = pdfDataToShare {
                    ShareSheet(activityItems: [data])
                }
            }
            .onAppear {
                generatePreview()
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: Theme.spacingL) {
            Spacer()

            ProgressView()
                .scaleEffect(1.4)
                .progressViewStyle(CircularProgressViewStyle(tint: Theme.primary))

            VStack(spacing: Theme.spacingS) {
                Text("Generating PDF…")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text("Preparing your inspection report")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }

    // MARK: - Error View

    private func errorView(message: String) -> some View {
        VStack(spacing: Theme.spacingL) {
            Spacer()

            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 56))
                .foregroundStyle(Theme.warning)

            VStack(spacing: Theme.spacingS) {
                Text("Preview Unavailable")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.spacingXL)
            }

            SSButton(
                "Try Again",
                style: .primary,
                icon: "arrow.clockwise"
            ) {
                errorMessage = nil
                isGenerating = true
                generatePreview()
            }
            .padding(.top, Theme.spacingM)

            Spacer()
        }
    }

    // MARK: - Empty View

    private var emptyView: some View {
        SSEmptyState(
            icon: "doc",
            title: "No PDF Available",
            message: "The PDF could not be loaded. Please try generating it again.",
            buttonTitle: "Retry",
            buttonAction: {
                isGenerating = true
                errorMessage = nil
                generatePreview()
            }
        )
    }

    // MARK: - PDFKit View

    private func pdfKitView(document: PDFDocument) -> some View {
        PDFKitView(document: document)
            .ignoresSafeArea(edges: .bottom)
    }

    // MARK: - PDF Generation

    private func generatePreview() {
        Task {
            do {
                let settings = EntitlementManager.shared.pdfExportSettings(
                    inspectorName: report.inspectorName,
                    companyName: fetchCompanyName()
                )
                let document = try PDFReportService.shared.previewPDF(for: report, settings: settings)

                // Save PDF reference to report
                if let pdfData = document.dataRepresentation() {
                    let filename = FileStorageService.shared.pdfFilename(for: report.id)
                    _ = try? FileStorageService.shared.savePDF(pdfData, filename: filename)

                    await MainActor.run {
                        report.latestPDFPath = filename
                        report.lastExportedAt = Date()
                        try? modelContext.save()
                    }
                }

                await MainActor.run {
                    self.pdfDocument = document
                    self.pdfDataToShare = document.dataRepresentation()
                    self.isGenerating = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isGenerating = false
                }
            }
        }
    }

    // MARK: - Helpers

    private func fetchCompanyName() -> String? {
        let descriptor = FetchDescriptor<UserProfile>()
        let profiles = (try? modelContext.fetch(descriptor)) ?? []
        return profiles.first?.companyName
    }
}

// MARK: - PDFKit UIViewRepresentable

/// A SwiftUI wrapper around PDFKit's PDFView for displaying PDF documents.
private struct PDFKitView: UIViewRepresentable {
    let document: PDFDocument

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = document
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.pageBreakMargins = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        pdfView.backgroundColor = UIColor.systemGroupedBackground
        return pdfView
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {
        pdfView.document = document
    }
}

// MARK: - Share Sheet

/// UIKit share sheet wrapper for sharing PDF data.
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

#Preview("PDF Preview") {
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

    let issue1 = InspectionIssue(title: "Cracked tile near sink", notes: "Visible crack in ceramic tile next to sink. Water may seep through.", severity: .high, status: .open)
    context.insert(issue1)
    issue1.report = report
    issue1.area = kitchen

    report.issues = [issue1]
    try? context.save()

    return PDFPreviewView(report: report)
        .modelContainer(container)
}
