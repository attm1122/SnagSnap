// SnagSnap
// StatsSummaryView.swift
//
// Horizontal row of 3 stat cards for the home dashboard.

import SwiftUI
import SwiftData
import Foundation

// MARK: - Stat Card

/// A single stat card showing an icon, large number, and label.
private struct StatCard: View {
    let icon: String
    let iconColor: Color
    let value: Int
    let label: String

    var body: some View {
        SSCard(
            padding: Theme.spacingM,
            cornerRadius: Theme.radiusLarge,
            shadowRadius: Theme.shadowRadiusSmall,
            shadowY: Theme.shadowYOffsetSmall,
            borderColor: iconColor.opacity(0.3)
        ) {
            VStack(spacing: Theme.spacingS) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(iconColor)
                    Spacer()
                }

                HStack {
                    Text("\(value)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.label)
                    Spacer()
                }

                HStack {
                    Text(label)
                        .font(Theme.fontCaption)
                        .foregroundStyle(Theme.secondaryLabel)
                    Spacer()
                }
            }
        }
        .frame(width: 120)
    }
}

// MARK: - Stats Summary View

/// A horizontally scrollable row of 3 stat cards.
///
/// Displays total reports, open issues, and completed reports
/// with animated number transitions.
struct StatsSummaryView: View {
    let stats: DashboardStats

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.spacingM) {
                StatCard(
                    icon: "doc.fill",
                    iconColor: Theme.primary,
                    value: stats.totalReports,
                    label: "Reports"
                )
                .entryAnimation(delay: 0.0)

                StatCard(
                    icon: "exclamationmark.triangle.fill",
                    iconColor: Theme.warning,
                    value: stats.openIssues,
                    label: "Open Issues"
                )
                .entryAnimation(delay: 0.05)

                StatCard(
                    icon: "checkmark.circle.fill",
                    iconColor: Theme.success,
                    value: stats.completedCount,
                    label: "Completed"
                )
                .entryAnimation(delay: 0.1)
            }
            .padding(.horizontal, Theme.spacingM)
        }
    }
}

// MARK: - Preview

#Preview("Stats Summary") {
    VStack(spacing: Theme.spacingL) {
        StatsSummaryView(stats: DashboardStats(totalReports: 12, openIssues: 5, completedCount: 3))
            .padding(.vertical, Theme.spacingM)

        Divider()

        StatsSummaryView(stats: DashboardStats.zero)
            .padding(.vertical, Theme.spacingM)
    }
    .background(Theme.groupedBackground)
}
