import SwiftUI

// MARK: - SSSectionHeader

/// A reusable section header with a title and an optional trailing action
/// button or navigation link.
struct SSSectionHeader: View {
    let title: String
    let actionTitle: String?
    let actionIcon: String?
    let action: (() -> Void)?

    // MARK: - Initializer

    /// Creates a new ``SSSectionHeader``.
    /// - Parameters:
    ///   - title: The header title text.
    ///   - actionTitle: Optional label for the trailing action.
    ///   - actionIcon: Optional SF Symbol name for the trailing action.
    ///   - action: Optional closure invoked when the action is tapped.
    init(
        _ title: String,
        actionTitle: String? = nil,
        actionIcon: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.actionTitle = actionTitle
        self.actionIcon = actionIcon
        self.action = action
    }

    // MARK: - Body

    var body: some View {
        HStack {
            Text(title)
                .font(Theme.headline)
                .foregroundStyle(.primary)

            Spacer()

            if let action = action {
                Button(action: action) {
                    HStack(spacing: Theme.spacingXS) {
                        if let actionTitle = actionTitle {
                            Text(actionTitle)
                                .font(Theme.callout)
                        }
                        if let actionIcon = actionIcon {
                            Image(systemName: actionIcon)
                                .font(.system(size: Theme.iconSizeS, weight: .semibold))
                        }
                    }
                    .foregroundStyle(Theme.secondaryAccent)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(actionTitle ?? "Action")
            }
        }
        .padding(.vertical, Theme.spacingS)
    }
}

// MARK: - Preview

#Preview("SSSectionHeader Variants") {
    VStack(spacing: Theme.spacingL) {
        // Title only
        SSSectionHeader("Recent Reports")

        // Title with text action
        SSSectionHeader(
            "All Issues",
            actionTitle: "See All",
            action: {}
        )

        // Title with icon action
        SSSectionHeader(
            "Photos",
            actionIcon: "plus",
            action: {}
        )

        // Title with both text and icon
        SSSectionHeader(
            "Team Members",
            actionTitle: "Add",
            actionIcon: "person.badge.plus",
            action: {}
        )
    }
    .padding(.horizontal, Theme.spacingM)
    .background(Theme.background)
}
