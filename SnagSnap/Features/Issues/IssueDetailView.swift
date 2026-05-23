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
    @State private var showFullScreenPhoto: Bool = false
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
                Button("Edit") {
                    showEditSheet = true
                }
                .foregroundStyle(Theme.primary)
            }
        }
        .sheet(isPresented: $showEditSheet) {
            if let report = issue.report, let area = issue.area {
                CreateEditIssueView(issue: issue, area: area, report: report)
            }
        }
        .fullScreenCover(isPresented: $showFullScreenPhoto) {
            if let photo = selectedPhoto {
                FullScreenPhotoView(photo: photo, dismiss: { showFullScreenPhoto = false })
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
                SSSectionHeader("Photos (\(issue.photoCount))")
                Spacer()
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.spacingM) {
                    ForEach(issue.photos ?? [], id: \.id) { photo in
                        PhotoThumbnailCard(photo: photo) {
                            selectedPhoto = photo
                            showFullScreenPhoto = true
                        }
                    }
                }
                .padding(.horizontal, Theme.spacingXS)
                .padding(.vertical, Theme.spacingXS)
            }
        }
    }
}

// MARK: - Photo Thumbnail Card

private struct PhotoThumbnailCard: View {
    let photo: IssuePhoto
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: Theme.spacingXS) {
                if let uiImage = FileStorageService.shared.loadThumbnail(from: photo.thumbnailImagePath) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMedium, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.radiusMedium, style: .continuous)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                        )
                        .overlay(annotationOverlay)
                } else {
                    RoundedRectangle(cornerRadius: Theme.radiusMedium, style: .continuous)
                        .fill(Color.gray.opacity(0.15))
                        .frame(width: 120, height: 120)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 32))
                                .foregroundStyle(.secondary.opacity(0.5))
                        )
                }

                if let caption = photo.caption, !caption.isEmpty {
                    Text(caption)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .frame(width: 120)
                }
            }
        }
        .buttonStyle(.plain)
    }

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
}

// MARK: - Full Screen Photo View

private struct FullScreenPhotoView: View {
    let photo: IssuePhoto
    let dismiss: () -> Void

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    private var displayImage: UIImage? {
        if let annotatedPath = photo.annotatedImagePath,
           let annotatedImage = FileStorageService.shared.loadImage(from: annotatedPath) {
            return annotatedImage
        }
        return FileStorageService.shared.loadImage(from: photo.originalImagePath)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if let uiImage = displayImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(magnificationGesture)
                        .gesture(dragGesture)
                        .onTapGesture(count: 2) {
                            withAnimation(.spring()) {
                                scale = 1.0
                                offset = .zero
                                lastScale = 1.0
                                lastOffset = .zero
                            }
                        }
                } else {
                    VStack(spacing: Theme.spacingM) {
                        Image(systemName: "photo")
                            .font(.system(size: 64))
                            .foregroundStyle(.secondary)
                        Text("Unable to load image")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle(photo.caption ?? "Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }
            }
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let delta = value / lastScale
                lastScale = value
                scale = min(max(scale * delta, 1.0), 5.0)
            }
            .onEnded { _ in
                lastScale = 1.0
                if scale < 1.0 {
                    withAnimation(.spring()) {
                        scale = 1.0
                    }
                }
            }
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                offset = CGSize(
                    width: lastOffset.width + value.translation.width,
                    height: lastOffset.height + value.translation.height
                )
            }
            .onEnded { _ in
                lastOffset = offset
            }
    }
}

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
