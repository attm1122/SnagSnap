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
        SSEmptyState(
            icon: "doc.text",
            title: "No reports yet",
            message: "Create your first property report and turn photos into a polished PDF in minutes.",
            buttonTitle: "New Report",
            buttonAction: action
        )
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
