import SwiftUI

/// A full-screen error state with animated icon and retry action.
struct ErrorStateView: View {

    let title: String
    let message: String?
    let retryAction: (() -> Void)?
    let dismissAction: (() -> Void)?

    @State private var showIcon = false
    @State private var showContent = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: Theme.spacingXL) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Theme.error.opacity(0.12))
                    .frame(width: 100, height: 100)

                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 56, weight: .medium))
                    .foregroundStyle(Theme.error)
                    .scaleEffect(showIcon ? 1.0 : 0.1)
                    .opacity(showIcon ? 1.0 : 0)
            }

            Text(title)
                .font(Theme.title)
                .foregroundStyle(.primary)
                .opacity(showContent ? 1.0 : 0)
                .offset(y: showContent ? 0 : 12)

            if let message = message {
                Text(message)
                    .font(Theme.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.spacingXL)
                    .opacity(showContent ? 1.0 : 0)
                    .offset(y: showContent ? 0 : 12)
            }

            Spacer()

            VStack(spacing: Theme.spacingM) {
                if let retry = retryAction {
                    SSButton(title: "Try Again", action: retry)
                        .opacity(showContent ? 1.0 : 0)
                        .offset(y: showContent ? 0 : 20)
                }
                if let dismiss = dismissAction {
                    SSButton(title: "Done", style: .tertiary, action: dismiss)
                        .opacity(showContent ? 1.0 : 0)
                        .offset(y: showContent ? 0 : 20)
                }
            }
            .padding(.horizontal, Theme.spacingXL)
            .padding(.bottom, Theme.spacingXXL)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background.ignoresSafeArea())
        .onAppear {
            let duration = reduceMotion ? 0.15 : 0.5
            withAnimation(.spring(response: duration, dampingFraction: 0.6)) {
                showIcon = true
            }
            withAnimation(.easeOut(duration: duration).delay(0.2)) {
                showContent = true
            }
            HapticService.shared.play(.error)
        }
    }
}

// MARK: - Preview

#Preview("Error - Retry & Dismiss") {
    ErrorStateView(
        title: "Something Went Wrong",
        message: "We couldn't generate your report. Please check your connection and try again.",
        retryAction: {},
        dismissAction: {}
    )
}

#Preview("Error - Retry Only") {
    ErrorStateView(
        title: "PDF Generation Failed",
        message: "An error occurred while building the PDF.",
        retryAction: {},
        dismissAction: nil
    )
}
