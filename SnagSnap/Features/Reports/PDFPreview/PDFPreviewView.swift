// SnagSnap
// PDFPreviewView.swift
//
// PDF preview using PDFKit with share functionality, dismiss support,
// error states, and entry animations.

import SwiftUI
import SwiftData
import PDFKit

// MARK: - PDFPreviewView

/// Displays a generated PDF report using PDFKit's native PDFView,
/// with toolbar controls for sharing (via ``ShareService``), dismissal,
/// error handling, and entry animations.
struct PDFPreviewView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Properties

    let report: InspectionReport
    let pdfData: Data?

    // MARK: - Local State

    @State private var pdfDocument: PDFDocument?
    @State private var isGenerating = true
    @State private var errorMessage: String?
    @State private var showShareSheet = false
    @State private var pdfDataToShare: Data?
    @State private var hasAppeared = false

    // MARK: - Initializer

    /// Creates a new ``PDFPreviewView``.
    /// - Parameters:
    ///   - report: The inspection report being previewed.
    ///   - pdfData: Optional pre-existing PDF data. If nil, the view will generate a new PDF.
    init(report: InspectionReport, pdfData: Data? = nil) {
        self.report = report
        self.pdfData = pdfData
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.groupedBackground.ignoresSafeArea()

                if isGenerating {
                    generatingView
                } else if let errorMessage = errorMessage {
                    ErrorStateView(
                        title: "Preview Unavailable",
                        message: errorMessage,
                        retryAction: {
                            errorMessage = nil
                            isGenerating = true
                            generatePreview()
                        },
                        dismissAction: {
                            dismiss()
                        }
                    )
                    .animateOnAppear(delay: 0, duration: 0.45)
                } else if let pdfDocument = pdfDocument {
                    pdfKitView(document: pdfDocument)
                        .opacity(hasAppeared ? 1 : 0)
                        .offset(y: hasAppeared ? 0 : 20)
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
                    if pdfDocument != nil {
                        Button {
                            sharePDF()
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                                .font(.body.weight(.medium))
                        }
                        .foregroundStyle(Theme.primary)
                    }
                }
            }
            .onAppear {
                if let pdfData = pdfData {
                    // Use pre-existing PDF data
                    if let document = PDFDocument(data: pdfData) {
                        self.pdfDocument = document
                        self.pdfDataToShare = pdfData
                        self.isGenerating = false
                        withAnimation(.easeOut(duration: 0.4)) {
                            hasAppeared = true
                        }
                    } else {
                        self.errorMessage = "The PDF data could not be loaded."
                        self.isGenerating = false
                    }
                } else {
                    generatePreview()
                }
            }
        }
    }

    // MARK: - Generating View

    private var generatingView: some View {
        VStack(spacing: Theme.spacingL) {
            Spacer()

            ProgressView()
                .scaleEffect(1.4)
                .progressViewStyle(CircularProgressViewStyle(tint: Theme.primary))

            VStack(spacing: Theme.spacingS) {
                Text("Loading PDF...")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text("Preparing your inspection report")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

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
                    withAnimation(.easeOut(duration: 0.4)) {
                        hasAppeared = true
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isGenerating = false
                }
            }
        }
    }

    // MARK: - Share

    private func sharePDF() {
        guard let data = pdfDataToShare ?? pdfDocument?.dataRepresentation() else { return }
        HapticService.shared.play(.light)

        // Update the last exported timestamp
        report.lastExportedAt = Date()
        try? modelContext.save()

        ShareService.shared.sharePDF(data, reportTitle: report.title)
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

    let issue1 = InspectionIssue(
        title: "Cracked tile near sink",
        notes: "Visible crack in ceramic tile next to sink. Water may seep through.",
        severity: .high,
        status: .open
    )
    context.insert(issue1)
    issue1.report = report
    issue1.area = kitchen

    report.issues = [issue1]
    try? context.save()

    return PDFPreviewView(report: report)
        .modelContainer(container)
}
