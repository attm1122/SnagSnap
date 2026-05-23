import SwiftUI

/// A full-screen success state with animated checkmark and action buttons.
struct SuccessStateView: View {
    struct Action {
        let title: String
        let icon: String?
        let handler: () -> Void

        init(title: String, icon: String? = nil, handler: @escaping () -> Void) {
            self.title = title
            self.icon = icon
            self.handler = handler
        }
    }

    let title: String
    let message: String?
    let primaryAction: Action
    let secondaryAction: Action?
    let tertiaryAction: Action?

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
                SSButton(primaryAction.title, icon: primaryAction.icon, isFullWidth: true, action: primaryAction.handler)
                    .opacity(showContent ? 1.0 : 0)
                    .offset(y: showContent ? 0 : 20)

                if let secondary = secondaryAction {
                    SSButton(secondary.title, style: .secondary, icon: secondary.icon, isFullWidth: true, action: secondary.handler)
                        .opacity(showContent ? 1.0 : 0)
                        .offset(y: showContent ? 0 : 20)
                }

                if let tertiary = tertiaryAction {
                    SSButton(tertiary.title, style: .tertiary, icon: tertiary.icon, action: tertiary.handler)
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
        primaryAction: .init(title: "View Report", handler: {}),
        secondaryAction: .init(title: "Share", handler: {}),
        tertiaryAction: .init(title: "Back to Home", handler: {})
    )
}

#Preview("Success - Primary Only") {
    SuccessStateView(
        title: "Inspection Saved",
        message: nil,
        primaryAction: .init(title: "Continue", handler: {}),
        secondaryAction: nil,
        tertiaryAction: nil
    )
}
