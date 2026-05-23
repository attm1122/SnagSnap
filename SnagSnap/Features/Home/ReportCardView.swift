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

    // MARK: - Body

    var body: some View {
        SSCard(
            padding: Theme.spacingM,
            cornerRadius: Theme.radiusMedium,
            shadowRadius: Theme.shadowRadiusSmall,
            shadowY: Theme.shadowYOffsetSmall
        ) {
            VStack(alignment: .leading, spacing: Theme.spacingS) {
                // Title and issue count
                HStack {
                    Text(report.title)
                        .font(Theme.fontHeadline)
                        .foregroundStyle(Theme.label)
                        .lineLimit(1)

                    Spacer()

                    IssueCountBadge(count: report.issueCount)
                }

                // Property name and address
                VStack(alignment: .leading, spacing: 4) {
                    Text(report.propertyName)
                        .font(Theme.fontSubheadline)
                        .foregroundStyle(Theme.secondaryLabel)
                        .lineLimit(1)

                    Text(report.propertyAddress)
                        .font(Theme.fontFootnote)
                        .foregroundStyle(Theme.tertiaryLabel)
                        .lineLimit(1)
                }

                Divider()

                // Bottom row: type badge, date, status
                HStack(spacing: Theme.spacingS) {
                    // Report type tag
                    SSTag(
                        report.reportType.displayName,
                        variant: .info,
                        icon: report.reportType.icon
                    )

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
                    }

                    // Status dot
                    StatusDot(color: report.status.color, size: 8)
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
        ZStack {
            Circle()
                .fill(Theme.primaryLight)
                .frame(width: 28, height: 28)

            Text("\(count)")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.primary)
        }
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
