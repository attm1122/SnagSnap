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
        SSCard(
            padding: Theme.spacingM,
            cornerRadius: Theme.radiusMedium,
            borderColor: borderColor.opacity(0.4),
            borderWidth: 1
        ) {
            VStack(alignment: .leading, spacing: Theme.spacingS) {
                topRow
                metadataRow
                if let preview = notesPreview {
                    notesPreviewView(preview)
                }
                if issue.hasPhotos {
                    photoThumbnailRow
                }
            }
        }
        .overlay(leftBorder, alignment: .leading)
    }

    // MARK: - Left Border

    private var leftBorder: some View {
        RoundedRectangle(cornerRadius: Theme.radiusMedium, style: .continuous)
            .fill(borderColor)
            .frame(width: 4)
    }

    // MARK: - Top Row

    private var topRow: some View {
        HStack(alignment: .top, spacing: Theme.spacingS) {
            VStack(alignment: .leading, spacing: 4) {
                Text(issue.title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                Text(areaName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }

    // MARK: - Metadata Row

    private var metadataRow: some View {
        HStack(spacing: Theme.spacingS) {
            SeverityIndicator(severity: issue.severity)
            IssueStatusBadge(status: issue.status)
            Spacer()
            Text(formattedDate(issue.createdAt))
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }

    // MARK: - Notes Preview

    private func notesPreviewView(_ preview: String) -> some View {
        Text(preview)
            .font(.caption)
            .foregroundStyle(.secondary)
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

    @ViewBuilder
    private func thumbnailImage(for photo: IssuePhoto) -> some View {
        if let uiImage = FileStorageService.shared.loadThumbnail(from: photo.thumbnailImagePath) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: Theme.radiusSmall, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.radiusSmall, style: .continuous)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                )
                .overlay(
                    photo.hasAnnotation ? annotationIndicator : nil
                )
        } else {
            RoundedRectangle(cornerRadius: Theme.radiusSmall, style: .continuous)
                .fill(Color.gray.opacity(0.15))
                .frame(width: 56, height: 56)
                .overlay(
                    Image(systemName: "photo")
                        .font(.system(size: 20))
                        .foregroundStyle(.secondary.opacity(0.5))
                )
        }
    }

    // MARK: - Annotation Indicator

    private var annotationIndicator: some View {
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

    // MARK: - Remaining Count Badge

    private func remainingCountBadge(_ count: Int) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: Theme.radiusSmall, style: .continuous)
                .fill(Color.gray.opacity(0.15))
                .frame(width: 56, height: 56)

            Text("+\(count)")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
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
