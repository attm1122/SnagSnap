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

                VStack(spacing: Theme.spacingL) {
                    SampleReportPreview()

                    // Text content
                    VStack(spacing: Theme.spacingM) {
                        Text("Create property reports in minutes")
                            .font(.system(size: 34, weight: .bold))
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
                    .buttonStyle(.animated(haptic: .medium))

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

private struct SampleReportPreview: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            HStack {
                Image(systemName: "doc.richtext.fill")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(Theme.primary, in: RoundedRectangle(cornerRadius: Theme.radiusMedium, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Inspection Report")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.primary)
                        .textCase(.uppercase)
                    Text("15 Oak Avenue")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Theme.ink)
                }

                Spacer()
            }

            HStack(spacing: Theme.spacingS) {
                previewStat("4", "Areas")
                previewStat("12", "Issues")
                previewStat("28", "Photos")
            }

            VStack(spacing: Theme.spacingS) {
                HStack {
                    Text("Cracked tile")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    Text("High")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Theme.warning)
                }
                .padding(.horizontal, Theme.spacingS)
                .padding(.vertical, 7)
                .background(Theme.background, in: RoundedRectangle(cornerRadius: Theme.radiusSmall, style: .continuous))
            }
        }
        .padding(Theme.spacingL)
        .frame(width: 286)
        .background(.white, in: RoundedRectangle(cornerRadius: Theme.radiusLarge, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radiusLarge, style: .continuous)
                .stroke(Theme.separator.opacity(0.45), lineWidth: 1)
        )
        .shadow(color: Theme.shadowColor, radius: 18, x: 0, y: 12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Sample property report preview with areas, issues, and photos")
    }

    private func previewStat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline.weight(.bold))
                .foregroundStyle(Theme.ink)
            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(Theme.secondaryLabel)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.spacingS)
        .background(Theme.blueSurface, in: RoundedRectangle(cornerRadius: Theme.radiusSmall, style: .continuous))
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
