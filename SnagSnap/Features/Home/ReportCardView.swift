// SnagSnap
// ReportCardView.swift
//
// Individual report card displayed in the recent reports list.

import SwiftUI
import SwiftData
import Foundation

// MARK: - Report Card View

/// A card displaying summary information for a single inspection report.
///
/// Shows the report title, property details, type badge, creation date,
/// issue count, and status indicator. Tapping navigates to the report workspace.
/// Supports swipe-to-delete with confirmation.
struct ReportCardView: View {
    let report: InspectionReport
    var onDelete: ((InspectionReport) -> Void)?
    var onTap: (() -> Void)?

    // MARK: - Body

    var body: some View {
        Button {
            HapticService.shared.play(.light)
            onTap?()
        } label: {
            cardContent
        }
        .buttonStyle(.animated(haptic: .light))
        .animation(.easeInOut(duration: 0.15), value: report.status)
    }

    // MARK: - Card Content

    private var cardContent: some View {
        SSCard(
            padding: Theme.spacingL,
            cornerRadius: Theme.radiusLarge,
            shadowRadius: Theme.shadowRadiusSmall,
            shadowY: Theme.shadowYOffsetSmall
        ) {
            VStack(alignment: .leading, spacing: Theme.spacingM) {
                // Title and issue count
                HStack(alignment: .top, spacing: Theme.spacingM) {
                    VStack(alignment: .leading, spacing: Theme.spacingXS) {
                        Text(report.title)
                            .font(Theme.fontHeadline.weight(.semibold))
                            .foregroundStyle(Theme.ink)
                            .lineLimit(2)

                        Text(report.reportType.displayName)
                            .font(Theme.fontCaption.weight(.medium))
                            .foregroundStyle(Theme.primary)
                            .padding(.horizontal, Theme.spacingS)
                            .padding(.vertical, 5)
                            .background(Theme.blueSurface, in: Capsule())
                    }

                    Spacer(minLength: Theme.spacingS)

                    ReportStatusBadge(status: report.status)
                }

                // Property name and address
                VStack(alignment: .leading, spacing: Theme.spacingXS) {
                    Text(report.propertyName)
                        .font(Theme.fontSubheadline.weight(.medium))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)

                    Text(report.propertyAddress)
                        .font(Theme.fontFootnote)
                        .foregroundStyle(Theme.secondaryLabel)
                        .lineLimit(2)
                }

                // Bottom row: type badge, date, status
                HStack(spacing: Theme.spacingS) {
                    IssueCountBadge(count: report.issueCount)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: report.issueCount)

                    Spacer()

                    // Creation date
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 10))
                            .foregroundStyle(Theme.tertiaryLabel)
                        Text(report.displayDate)
                            .font(Theme.fontFootnote)
                            .foregroundStyle(Theme.secondaryLabel)
                    }

                    // PDF exported indicator
                    if report.hasExportedPDF {
                        Image(systemName: "doc.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(Theme.success)
                            .accessibilityLabel("PDF exported")
                            .scaleEntryAnimation(delay: 0.1)
                    }

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.tertiaryLabel)
                }
            }
        }
    }
}

// MARK: - Issue Count Badge

/// A small circular badge showing the issue count.
private struct IssueCountBadge: View {
    let count: Int

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.caption2.weight(.semibold))
            Text("\(count)")
                .font(.caption.weight(.semibold))
                .contentTransition(.numericText())
            Text(count == 1 ? "issue" : "issues")
                .font(.caption.weight(.medium))
        }
        .foregroundStyle(count > 0 ? Theme.secondaryAccent : Theme.secondaryLabel)
        .padding(.horizontal, Theme.spacingS)
        .padding(.vertical, 6)
        .background((count > 0 ? Theme.secondaryAccent : Theme.secondaryLabel).opacity(0.1), in: Capsule())
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: count)
    }
}

// MARK: - Preview

#Preview("Report Cards") {
    ScrollView {
        VStack(spacing: Theme.spacingM) {
            // We would need a real InspectionReport instance for preview
            // Using a placeholder description instead
            Text("ReportCardView displays:\n- Report title (headline)\n- Property name + address\n- Report type badge with icon\n- Creation date\n- Issue count badge\n- Status colored dot")
                .font(Theme.fontBody)
                .foregroundStyle(Theme.secondaryLabel)
                .multilineTextAlignment(.center)
                .padding(Theme.spacingXL)
        }
        .padding(Theme.spacingM)
    }
    .background(Theme.groupedBackground)
}
