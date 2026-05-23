import SwiftUI

/// A full-screen success state with animated checkmark and action buttons.
struct SuccessStateView: View {

    let title: String
    let message: String?
    let primaryAction: (title: String, action: () -> Void)
    let secondaryAction: (title: String, action: () -> Void)?
    let tertiaryAction: (title: String, action: () -> Void)?

    @State private var showCheckmark = false
    @State private var showContent = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: Theme.spacingXL) {
            Spacer()

            // Animated checkmark
            ZStack {
                Circle()
                    .fill(Theme.success.opacity(0.12))
                    .frame(width: 100, height: 100)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64, weight: .medium))
                    .foregroundStyle(Theme.success)
                    .scaleEffect(showCheckmark ? 1.0 : 0.1)
                    .opacity(showCheckmark ? 1.0 : 0)
            }

            // Title
            Text(title)
                .font(Theme.title)
                .foregroundStyle(.primary)
                .opacity(showContent ? 1.0 : 0)
                .offset(y: showContent ? 0 : 12)

            // Message
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

            // Actions
            VStack(spacing: Theme.spacingM) {
                SSButton(title: primaryAction.title, action: primaryAction.action)
                    .opacity(showContent ? 1.0 : 0)
                    .offset(y: showContent ? 0 : 20)

                if let secondary = secondaryAction {
                    SSButton(title: secondary.title, style: .secondary, action: secondary.action)
                        .opacity(showContent ? 1.0 : 0)
                        .offset(y: showContent ? 0 : 20)
                }

                if let tertiary = tertiaryAction {
                    SSButton(title: tertiary.title, style: .tertiary, action: tertiary.action)
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
            let baseDelay = reduceMotion ? 0.1 : 0.3
            let duration = reduceMotion ? 0.15 : 0.5

            withAnimation(.spring(response: duration, dampingFraction: 0.6)) {
                showCheckmark = true
            }
            withAnimation(.easeOut(duration: duration).delay(baseDelay + 0.1)) {
                showContent = true
            }
            HapticService.shared.play(.success)
        }
    }
}

// MARK: - Preview

#Preview("Success - All Actions") {
    SuccessStateView(
        title: "Report Generated!",
        message: "Your PDF report has been successfully created and saved.",
        primaryAction: (title: "View Report", action: {}),
        secondaryAction: (title: "Share", action: {}),
        tertiaryAction: (title: "Back to Home", action: {})
    )
}

#Preview("Success - Primary Only") {
    SuccessStateView(
        title: "Inspection Saved",
        message: nil,
        primaryAction: (title: "Continue", action: {}),
        secondaryAction: nil,
        tertiaryAction: nil
    )
}
