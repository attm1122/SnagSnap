// SnagSnap
// IssueDetailView.swift
//
// Detail view for viewing an issue (read-only) with photo gallery.

import SwiftUI
import SwiftData

// MARK: - IssueDetailView

/// Read-only detail view for viewing a complete inspection issue.
/// Displays full issue information, a scrollable photo gallery,
/// and provides an edit button to enter edit mode.
struct IssueDetailView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AppRouter.self) private var router

    // MARK: - Properties

    let issue: InspectionIssue

    // MARK: - Local State

    @State private var selectedPhoto: IssuePhoto?
    @State private var showImageViewer: Bool = false
    @State private var viewerShowAnnotated: Bool = false
    @State private var showEditSheet: Bool = false

    // MARK: - Computed Properties

    private var areaName: String {
        issue.area?.name ?? "No Area"
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.spacingL) {
                titleHeader
                metadataSection
                statusSection
                if let notes = issue.notes, !notes.isEmpty {
                    notesSection(notes)
                }
                if issue.hasPhotos {
                    photosSection
                }
            }
            .padding(Theme.spacingM)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Issue Details")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: Theme.spacingS) {
                    // Share menu
                    if let photos = issue.photos, !photos.isEmpty {
                        Menu {
                            Button {
                                shareAllImages()
                            } label: {
                                Label("Share All Photos", systemImage: "square.and.arrow.up")
                            }

                            Button {
                                shareAnnotatedOnly()
                            } label: {
                                Label("Share Annotated Only", systemImage: "pencil.circle")
                            }
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                        }
                        .foregroundStyle(Theme.primary)
                    }

                    Button("Edit") {
                        showEditSheet = true
                    }
                    .foregroundStyle(Theme.primary)
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            if let report = issue.report, let area = issue.area {
                CreateEditIssueView(issue: issue, area: area, report: report)
            }
        }
        .sheet(isPresented: $showImageViewer) {
            if let photo = selectedPhoto {
                ImageViewerView(photo: photo, initialShowAnnotated: viewerShowAnnotated)
            }
        }
    }

    // MARK: - Title Header

    private var titleHeader: some View {
        VStack(alignment: .leading, spacing: Theme.spacingS) {
            HStack(alignment: .top) {
                Text(issue.title)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.primary)

                Spacer()
            }

            HStack(spacing: Theme.spacingXS) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(areaName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Metadata Section

    private var metadataSection: some View {
        SSCard {
            HStack(spacing: Theme.spacingL) {
                metadataItem(
                    icon: issue.severity.icon,
                    label: "Severity",
                    value: issue.severity.displayName,
                    color: issue.severity.color
                )

                Divider()

                metadataItem(
                    icon: issue.status.icon,
                    label: "Status",
                    value: issue.status.displayName,
                    color: issue.status.color
                )
            }
        }
    }

    private func metadataItem(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(spacing: Theme.spacingXS) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Status Section

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingS) {
            SSSectionHeader("Status Overview")

            HStack(spacing: Theme.spacingM) {
                SeverityIndicator(severity: issue.severity)
                IssueStatusBadge(status: issue.status)
                Spacer()
            }
        }
    }

    // MARK: - Notes Section

    private func notesSection(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: Theme.spacingS) {
            SSSectionHeader("Notes")

            SSCard {
                Text(notes)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: - Photos Section

    private var photosSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingS) {
            HStack {
                let includedCount = (issue.photos ?? []).filter(\.includeInReport).count
                let totalCount = issue.photoCount
                if includedCount < totalCount {
                    SSSectionHeader("Photos (\(totalCount)) — \(includedCount) in PDF")
                } else {
                    SSSectionHeader("Photos (\(totalCount))")
                }
                Spacer()
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.spacingM) {
                    ForEach(issue.photos ?? [], id: \.id) { photo in
                        PhotoThumbnailCard(
                            photo: photo,
                            onTap: {
                                selectedPhoto = photo
                                viewerShowAnnotated = false
                                showImageViewer = true
                            },
                            onTapAnnotated: {
                                selectedPhoto = photo
                                viewerShowAnnotated = true
                                showImageViewer = true
                            }
                        )
                    }
                }
                .padding(.horizontal, Theme.spacingXS)
                .padding(.vertical, Theme.spacingXS)
            }
        }
    }

    // MARK: - Share Actions

    private func shareAllImages() {
        let photos = issue.photos ?? []
        let images = photos.compactMap { photo -> UIImage? in
            if let annotatedPath = photo.annotatedImagePath,
               let annotatedImage = FileStorageService.shared.loadAnnotatedImage(from: annotatedPath) {
                return annotatedImage
            }
            return FileStorageService.shared.loadImage(from: photo.originalImagePath)
        }
        guard !images.isEmpty else { return }
        ShareService.shared.shareImages(images, caption: issue.title)
    }

    private func shareAnnotatedOnly() {
        let photos = issue.photos ?? []
        let images = photos.compactMap { photo -> UIImage? in
            guard let annotatedPath = photo.annotatedImagePath else { return nil }
            return FileStorageService.shared.loadAnnotatedImage(from: annotatedPath)
        }
        guard !images.isEmpty else { return }
        ShareService.shared.shareImages(images, caption: "\(issue.title) — Annotated")
    }
}

// MARK: - Photo Thumbnail Card

private struct PhotoThumbnailCard: View {
    let photo: IssuePhoto
    let onTap: () -> Void
    let onTapAnnotated: (() -> Void)?

    var body: some View {
        VStack(spacing: Theme.spacingXS) {
            thumbnailContent

            if let caption = photo.caption, !caption.isEmpty {
                Text(caption)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .frame(width: 120)
            }
        }
    }

    // MARK: - Thumbnail Content

    private var thumbnailContent: some View {
        StoredThumbnailImage(path: photo.thumbnailImagePath)
            .frame(width: 120, height: 120)
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMedium, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radiusMedium, style: .continuous)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
            )
            .overlay(annotationOverlay)
            .overlay(includeInReportOverlay)
            .onTapGesture {
                onTap()
            }
            .contextMenu {
                Button {
                    onTap()
                } label: {
                    Label("View Original", systemImage: "eye")
                }

                if photo.hasAnnotation {
                    Button {
                        onTapAnnotated?()
                    } label: {
                        Label("View Annotated", systemImage: "pencil.circle")
                    }
                }

                Button {
                    shareImage()
                } label: {
                    Label("Share Image", systemImage: "square.and.arrow.up")
                }
            }
    }

    // MARK: - Annotation Overlay

    @ViewBuilder
    private var annotationOverlay: some View {
        if photo.hasAnnotation {
            VStack {
                HStack {
                    Spacer()
                    Image(systemName: "pencil.tip.crop.circle.badge.plus.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.white)
                        .shadow(radius: 2)
                        .padding(6)
                }
                Spacer()
            }
            .frame(width: 120, height: 120)
        }
    }

    // MARK: - Include in Report Overlay

    @ViewBuilder
    private var includeInReportOverlay: some View {
        if !photo.includeInReport {
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.red.opacity(0.9))
                        .background(Circle().fill(.white))
                        .padding(4)
                }
            }
            .frame(width: 120, height: 120)
        }
    }

    // MARK: - Share

    private func shareImage() {
        let image: UIImage?
        if let annotatedPath = photo.annotatedImagePath {
            image = FileStorageService.shared.loadAnnotatedImage(from: annotatedPath)
                ?? FileStorageService.shared.loadImage(from: photo.originalImagePath)
        } else {
            image = FileStorageService.shared.loadImage(from: photo.originalImagePath)
        }
        guard let imageToShare = image else { return }
        ShareService.shared.shareImage(imageToShare, caption: photo.caption)
    }
}

// MARK: - Preview

// MARK: - Preview

#Preview("Issue Detail") {
    let container = try! PreviewContainer()
    let issue = container.sampleReport.issues!.first!

    return NavigationStack {
        IssueDetailView(issue: issue)
    }
    .modelContainer(container.container)
}

// MARK: - Preview Helpers

private struct PreviewContainer {
    let container: ModelContainer
    let sampleReport: InspectionReport

    init() throws {
        let schema = Schema([InspectionReport.self, InspectionArea.self, InspectionIssue.self, IssuePhoto.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])

        let context = ModelContext(container)
        sampleReport = InspectionReport(
            title: "Sample Report",
            propertyName: "123 Main St",
            propertyAddress: "123 Main Street, London",
            reportType: .snagging
        )
        context.insert(sampleReport)

        let kitchen = InspectionArea(name: "Kitchen", notes: "Main kitchen")
        context.insert(kitchen)
        kitchen.report = sampleReport
        sampleReport.areas = [kitchen]

        let issue1 = InspectionIssue(title: "Cracked tile near sink", notes: "A large crack is visible in the ceramic tile next to the kitchen sink. Water may seep through and cause further damage if not addressed promptly.", severity: .high, status: .open)
        context.insert(issue1)
        issue1.report = sampleReport
        issue1.area = kitchen

        sampleReport.issues = [issue1]

        try context.save()
    }
}
