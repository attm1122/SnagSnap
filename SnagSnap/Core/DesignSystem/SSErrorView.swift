import SwiftUI

// MARK: - SSErrorView

/// A reusable error display view with an icon, title, message, and a retry button.
struct SSErrorView: View {
    let icon: String
    let title: String
    let message: String?
    let retryTitle: String?
    let onRetry: (() -> Void)?

    // MARK: - Initializer

    /// Creates a new ``SSErrorView``.
    /// - Parameters:
    ///   - icon: SF Symbol name for the decorative icon (default `"exclamationmark.triangle"`).
    ///   - title: Headline text describing the error.
    ///   - message: Optional detailed error description.
    ///   - retryTitle: Optional label for the retry button (default `"Try Again"`).
    ///   - onRetry: Optional closure invoked when the retry button is tapped.
    init(
        icon: String = "exclamationmark.triangle",
        title: String,
        message: String? = nil,
        retryTitle: String = "Try Again",
        onRetry: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.retryTitle = onRetry != nil ? retryTitle : nil
        self.onRetry = onRetry
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: Theme.spacingL) {
            Spacer()

            // Icon
            Image(systemName: icon)
                .font(.system(size: 56, weight: .medium))
                .foregroundStyle(Theme.error.opacity(0.8))
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

            // Retry button
            if let onRetry = onRetry, let retryTitle = retryTitle {
                SSButton(
                    retryTitle,
                    style: .primary,
                    icon: "arrow.clockwise",
                    isFullWidth: false,
                    action: onRetry
                )
                .padding(.top, Theme.spacingS)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Theme.spacingL)
        .background(Theme.background)
    }
}

// MARK: - Preview

#Preview("SSErrorView Variants") {
    TabView {
        // With retry
        SSErrorView(
            title: "Something Went Wrong",
            message: "We couldn't load your reports. Please check your connection and try again.",
            onRetry: {}
        )
        .tabItem { Label("With Retry", systemImage: "1.circle") }

        // Without retry
        SSErrorView(
            icon: "wifi.slash",
            title: "No Internet Connection",
            message: "Connect to Wi-Fi or cellular data to access your reports."
        )
        .tabItem { Label("No Retry", systemImage: "2.circle") }

        // Minimal
        SSErrorView(
            icon: "lock.slash",
            title: "Access Denied"
        )
        .tabItem { Label("Minimal", systemImage: "3.circle") }
    }
}
