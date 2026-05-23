// SnagSnap
// EmptyStates.swift
//
// Reusable empty state configurations for the home dashboard.

import SwiftUI
import SwiftData
import Foundation

// MARK: - No Reports Empty State

/// Empty state shown when no inspection reports exist.
///
/// Displays a friendly message encouraging the user to create their first report.
struct NoReportsEmptyState: View {
    var action: () -> Void

    var body: some View {
        VStack(spacing: Theme.spacingL) {
            Image(systemName: "doc.text")
                .font(.system(size: 52, weight: .light))
                .foregroundStyle(Theme.tertiaryLabel)
                .accessibilityHidden(true)

            VStack(spacing: Theme.spacingS) {
                Text("No reports yet")
                    .font(Theme.fontTitle3)
                    .foregroundStyle(Theme.label)
                    .multilineTextAlignment(.center)

                Text("Create your first property report and turn photos into a polished PDF in minutes.")
                    .font(Theme.fontBody)
                    .foregroundStyle(Theme.secondaryLabel)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: 340)

            SSButton("New Report", style: .primary, icon: "plus", action: action)
                .buttonStyle(.animated(haptic: .medium))
                .padding(.top, Theme.spacingXS)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, Theme.spacingL)
        .padding(.vertical, Theme.spacingXL)
    }
}

// MARK: - No Search Results Empty State

/// Empty state shown when a search query returns no results.
struct NoSearchResultsEmptyState: View {
    let query: String
    var onClear: () -> Void

    var body: some View {
        VStack(spacing: Theme.spacingL) {
            Spacer()

            Image(systemName: "magnifyingglass")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(Theme.tertiaryLabel)
                .accessibilityHidden(true)

            Text("No results for \"\(query)\"")
                .font(Theme.fontHeadline)
                .foregroundStyle(Theme.label)
                .multilineTextAlignment(.center)

            Text("Try a different search term or check your spelling.")
                .font(Theme.fontSubheadline)
                .foregroundStyle(Theme.secondaryLabel)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.spacingXL)

            SSButton("Clear Search", style: .secondary, action: onClear)
                .padding(.top, Theme.spacingS)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Theme.spacingL)
    }
}

// MARK: - Preview

#Preview("Empty States") {
    TabView {
        NoReportsEmptyState(action: {})
            .tabItem { Label("No Reports", systemImage: "1.circle") }

        NoSearchResultsEmptyState(query: "kitchen", onClear: {})
            .tabItem { Label("No Results", systemImage: "2.circle") }
    }
    .background(Theme.groupedBackground)
}
