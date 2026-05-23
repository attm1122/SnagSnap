import SwiftUI

// MARK: - SSEmptyState

/// A reusable empty-state view that displays an SF Symbol icon, a title,
/// an optional message, and an optional action button.
struct SSEmptyState: View {
    let icon: String
    let title: String
    let message: String?
    let buttonTitle: String?
    let buttonAction: (() -> Void)?

    // MARK: - Initializer

    /// Creates a new ``SSEmptyState``.
    /// - Parameters:
    ///   - icon: SF Symbol name for the decorative icon.
    ///   - title: Headline text displayed below the icon.
    ///   - message: Optional descriptive body text.
    ///   - buttonTitle: Optional label for the bottom action button.
    ///   - buttonAction: Optional closure invoked when the action button is tapped.
    init(
        icon: String,
        title: String,
        message: String? = nil,
        buttonTitle: String? = nil,
        buttonAction: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.buttonTitle = buttonTitle
        self.buttonAction = buttonAction
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: Theme.spacingL) {
            Spacer()

            // Icon
            Image(systemName: icon)
                .font(.system(size: 64, weight: .light))
                .foregroundStyle(Theme.primary.opacity(0.35))
                .accessibilityHidden(true)

            // Title
            Text(title)
                .font(Theme.title3)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)

            // Message
            if let message = message {
                Text(message)
                    .font(Theme.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.spacingXL)
            }

            // Action button
            if let buttonTitle = buttonTitle, let buttonAction = buttonAction {
                SSButton(
                    buttonTitle,
                    style: .primary,
                    icon: "plus",
                    isFullWidth: false,
                    action: buttonAction
                )
                .padding(.top, Theme.spacingS)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Theme.spacingL)
    }
}

// MARK: - Preview

#Preview("SSEmptyState Variants") {
    TabView {
        // With message and button
        SSEmptyState(
            icon: "folder.badge.plus",
            title: "No Reports Yet",
            message: "Create your first snag report to get started tracking issues.",
            buttonTitle: "Create Report",
            buttonAction: {}
        )
        .tabItem { Label("With Action", systemImage: "1.circle") }

        // Title only
        SSEmptyState(
            icon: "magnifyingglass",
            title: "No Results Found"
        )
        .tabItem { Label("Title Only", systemImage: "2.circle") }

        // Title + message, no button
        SSEmptyState(
            icon: "bell.slash",
            title: "All Caught Up",
            message: "You have no new notifications at this time."
        )
        .tabItem { Label("No Action", systemImage: "3.circle") }
    }
}
