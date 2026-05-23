// SnagSnap
// WelcomeView.swift
//
// Screen 1 of the onboarding flow — Welcome / hero screen.

import SwiftUI

// MARK: - WelcomeView

/// The first onboarding screen presenting the app's value proposition.
///
/// Features a large centered SF Symbol illustration, headline title,
/// descriptive body text, and a primary "Get Started" call-to-action.
struct WelcomeView: View {

    // MARK: - Properties

    /// The shared onboarding view model.
    let viewModel: OnboardingViewModel

    /// Callback invoked when the user taps "Get Started".
    let onGetStarted: () -> Void

    /// Callback invoked when the user taps "Skip".
    let onSkip: () -> Void

    // MARK: - Body

    var body: some View {
        ZStack {
            Theme.groupedBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    Button {
                        onSkip()
                    } label: {
                        Text("Skip")
                            .font(Theme.fontCallout)
                            .foregroundStyle(Theme.secondaryLabel)
                            .padding(.vertical, Theme.spacingS)
                            .padding(.horizontal, Theme.spacingM)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, Theme.spacingM)
                .padding(.top, Theme.spacingM)

                Spacer()

                // Illustration and text content
                VStack(spacing: Theme.spacingXL) {
                    // Icon with decorative background
                    ZStack {
                        Circle()
                            .fill(Theme.primary.opacity(0.12))
                            .frame(width: 180, height: 180)

                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 80, weight: .medium))
                            .foregroundStyle(Theme.primary)
                    }

                    // Text content
                    VStack(spacing: Theme.spacingM) {
                        Text("Create property reports in minutes")
                            .font(Theme.fontLargeTitle)
                            .foregroundStyle(Theme.label)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Theme.spacingL)

                        Text("Capture photos, record issues and export polished PDF reports directly from your iPhone.")
                            .font(Theme.fontBody)
                            .foregroundStyle(Theme.secondaryLabel)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .padding(.horizontal, Theme.spacingXL)
                    }
                }

                Spacer()

                // Bottom action button
                VStack(spacing: Theme.spacingL) {
                    SSButton(
                        "Get Started",
                        style: .primary,
                        icon: "arrow.right",
                        isFullWidth: true,
                        action: onGetStarted
                    )

                    // Page indicator
                    HStack(spacing: Theme.spacingS) {
                        ForEach(0..<viewModel.totalPages, id: \.self) { index in
                            Capsule()
                                .fill(index == 0 ? Theme.primary : Theme.primary.opacity(0.2))
                                .frame(width: index == 0 ? 20 : 8, height: 8)
                                .animation(.easeInOut(duration: 0.25), value: viewModel.currentPage)
                        }
                    }
                }
                .padding(.horizontal, Theme.spacingXL)
                .padding(.bottom, Theme.spacingXL)
            }
        }
    }
}

// MARK: - Preview

#Preview("Welcome Screen") {
    let vm = OnboardingViewModel()
    WelcomeView(
        viewModel: vm,
        onGetStarted: {},
        onSkip: {}
    )
}

#Preview("Welcome Screen - Dark") {
    let vm = OnboardingViewModel()
    WelcomeView(
        viewModel: vm,
        onGetStarted: {},
        onSkip: {}
    )
    .preferredColorScheme(.dark)
}
