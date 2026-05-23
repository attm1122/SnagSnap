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
            borderColor: Theme.separator.opacity(0.65)
        ) {
            VStack(alignment: .leading, spacing: Theme.spacingM) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(iconColor)
                    .frame(width: 38, height: 38)
                    .background(iconColor.opacity(0.11), in: Circle())

                Text("\(value)")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(Theme.ink)
                    .contentTransition(.numericText())

                Text(label)
                    .font(Theme.fontCaption.weight(.medium))
                    .foregroundStyle(Theme.secondaryLabel)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
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
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: Theme.spacingS) {
            StatCard(
                icon: "doc.text.fill",
                iconColor: Theme.primary,
                value: stats.totalReports,
                label: "Reports"
            )
            .entryAnimation(delay: 0.0)

            StatCard(
                icon: "exclamationmark.triangle.fill",
                iconColor: Theme.secondaryAccent,
                value: stats.openIssues,
                label: "Open"
            )
            .entryAnimation(delay: 0.05)

            StatCard(
                icon: "checkmark.seal.fill",
                iconColor: Theme.accent,
                value: stats.completedCount,
                label: "Done"
            )
            .entryAnimation(delay: 0.1)
        }
        .padding(.horizontal, Theme.spacingL)
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
