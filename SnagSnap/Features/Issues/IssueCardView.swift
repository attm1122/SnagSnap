// SnagSnap
// IssueCardView.swift
//
// Reusable issue card component for compact list views.

import SwiftUI
import SwiftData

// MARK: - IssueCardView

/// A reusable card view displaying an issue's key information in a compact layout.
/// Shows title, area name, severity indicator, status badge, and photo thumbnail.
struct IssueCardView: View {

    // MARK: - Properties

    let issue: InspectionIssue
    var onTap: (() -> Void)?

    // MARK: - Computed Properties

    private var areaName: String {
        issue.area?.name ?? "No Area"
    }

    private var borderColor: Color {
        issue.severity.color
    }

    private var notesPreview: String? {
        guard let notes = issue.notes, !notes.isEmpty else { return nil }
        if notes.count > 120 {
            return String(notes.prefix(120)) + "\u{2026}"
        }
        return notes
    }

    // MARK: - Body

    var body: some View {
        Button {
            HapticService.shared.play(.light)
            onTap?()
        } label: {
            cardContent
        }
        .buttonStyle(.animated(haptic: .light))
        .animation(.easeInOut(duration: 0.2), value: issue.severity)
        .animation(.easeInOut(duration: 0.2), value: issue.status)
    }

    // MARK: - Card Content

    private var cardContent: some View {
        SSCard(
            padding: Theme.spacingM,
            cornerRadius: Theme.radiusLarge,
            borderColor: Theme.separator.opacity(0.7),
            borderWidth: 1
        ) {
            VStack(alignment: .leading, spacing: Theme.spacingM) {
                topRow
                metadataRow
                if let preview = notesPreview {
                    notesPreviewView(preview)
                }
                if issue.hasPhotos {
                    photoThumbnailRow
                        .scaleEntryAnimation(delay: 0.05)
                }
            }
        }
        .overlay(leftBorder, alignment: .leading)
    }

    // MARK: - Left Border

    private var leftBorder: some View {
        RoundedRectangle(cornerRadius: Theme.radiusLarge, style: .continuous)
            .fill(borderColor)
            .frame(width: 3)
    }

    // MARK: - Top Row

    private var topRow: some View {
        HStack(alignment: .top, spacing: Theme.spacingS) {
            VStack(alignment: .leading, spacing: 4) {
                Text(issue.title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(2)

                Label(areaName, systemImage: "mappin.and.ellipse")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Theme.secondaryLabel)
            }

            Spacer()
        }
    }

    // MARK: - Metadata Row

    private var metadataRow: some View {
        HStack(spacing: Theme.spacingS) {
            SeverityIndicator(severity: issue.severity)
                .animation(.easeInOut(duration: 0.2), value: issue.severity)

            IssueStatusBadge(status: issue.status)
                .animation(.easeInOut(duration: 0.15), value: issue.status)

            if issue.hasPhotos {
                photoCountIndicator
            }

            if hasAnyAnnotatedPhotos {
                annotationIndicator
            }

            Spacer()
            Text(formattedDate(issue.createdAt))
                .font(.caption2)
                .foregroundStyle(Theme.tertiaryLabel)
        }
    }

    // MARK: - Photo Count Indicator

    private var photoCountIndicator: some View {
        let includedCount = (issue.photos ?? []).filter(\.includeInReport).count
        let totalCount = issue.photoCount
        let iconName = totalCount == 1 ? "photo" : "photo.stack"

        return HStack(spacing: 2) {
            Image(systemName: iconName)
                .font(.caption2)
            if includedCount < totalCount {
                Text("\(includedCount)/\(totalCount)")
                    .font(.caption2.weight(.medium))
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: includedCount)
            } else {
                Text("\(totalCount)")
                    .font(.caption2.weight(.medium))
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: totalCount)
            }
        }
        .foregroundStyle(Theme.secondaryLabel)
    }

    // MARK: - Annotation Indicator

    private var annotationIndicator: some View {
        HStack(spacing: 2) {
            Image(systemName: "pencil.circle")
                .font(.caption2)
        }
        .foregroundStyle(Theme.primary)
    }

    // MARK: - Computed Properties

    private var hasAnyAnnotatedPhotos: Bool {
        issue.photos?.contains(where: \.hasAnnotation) ?? false
    }

    // MARK: - Notes Preview

    private func notesPreviewView(_ preview: String) -> some View {
        Text(preview)
            .font(.caption)
            .foregroundStyle(Theme.secondaryLabel)
            .lineLimit(2)
            .padding(.top, 2)
    }

    // MARK: - Photo Thumbnail Row

    private var photoThumbnailRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.spacingS) {
                ForEach(issue.photos?.prefix(4) ?? [], id: \.id) { photo in
                    thumbnailImage(for: photo)
                }

                if let photos = issue.photos, photos.count > 4 {
                    remainingCountBadge(photos.count - 4)
                }
            }
        }
        .padding(.top, Theme.spacingXS)
    }

    // MARK: - Thumbnail Image

    private func thumbnailImage(for photo: IssuePhoto) -> some View {
        StoredThumbnailImage(path: photo.thumbnailImagePath)
            .frame(width: 56, height: 56)
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusSmall, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radiusSmall, style: .continuous)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
            )
            .overlay(
                photo.hasAnnotation ? thumbnailAnnotationBadge : nil
            )
            .overlay(
                !photo.includeInReport ? thumbnailExcludedBadge : nil
            )
    }

    // MARK: - Thumbnail Annotation Badge

    private var thumbnailAnnotationBadge: some View {
        VStack {
            HStack {
                Spacer()
                Image(systemName: "pencil.tip.crop.circle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.white)
                    .shadow(radius: 1)
                    .padding(2)
            }
            Spacer()
        }
    }

    // MARK: - Thumbnail Excluded Badge

    private var thumbnailExcludedBadge: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(.red.opacity(0.9))
                    .background(Circle().fill(.white))
                    .padding(2)
            }
        }
    }

    // MARK: - Remaining Count Badge

    private func remainingCountBadge(_ count: Int) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: Theme.radiusSmall, style: .continuous)
                .fill(Theme.blueSurface)
                .frame(width: 56, height: 56)

            Text("+\(count)")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Theme.secondaryLabel)
        }
    }

    // MARK: - Date Formatting

    private func formattedDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Preview

#Preview("Issue Cards") {
    let container = try! PreviewContainer()
    let issues = container.sampleReport.issues ?? []

    ScrollView {
        VStack(spacing: Theme.spacingM) {
            ForEach(issues, id: \.id) { issue in
                IssueCardView(issue: issue)
            }
        }
        .padding(Theme.spacingM)
    }
    .background(Color(.systemGroupedBackground))
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

        let issue1 = InspectionIssue(title: "Cracked tile near sink", notes: "A large crack is visible in the ceramic tile next to the kitchen sink. Water may seep through.", severity: .high, status: .open)
        context.insert(issue1)
        issue1.report = sampleReport
        issue1.area = kitchen

        let issue2 = InspectionIssue(title: "Loose cabinet handle", notes: "Handle on lower cabinet is loose and wobbles.", severity: .low, status: .inProgress)
        context.insert(issue2)
        issue2.report = sampleReport
        issue2.area = kitchen

        let issue3 = InspectionIssue(title: "Missing grout in corner", severity: .medium, status: .open)
        context.insert(issue3)
        issue3.report = sampleReport
        issue3.area = kitchen

        sampleReport.issues = [issue1, issue2, issue3]

        try context.save()
    }
}
