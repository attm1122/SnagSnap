// SnagSnap
// OnboardingView.swift
//
// Root onboarding container with page-based navigation (TabView + .page style).

import SwiftUI
import SwiftData

// MARK: - OnboardingView

/// The root onboarding container that manages the 3-screen onboarding flow.
///
/// Uses a ``TabView`` with the `.tabViewStyle(.page(indexDisplayMode: .never))` style
/// to present three onboarding screens:
/// 1. ``WelcomeView`` — Hero introduction and value proposition.
/// 2. ``UseCaseSelectionView`` — Multi-select use case cards.
/// 3. ``BrandingSetupView`` — Profile / branding form.
///
/// Page transitions are animated, and a custom page indicator is shown on each screen.
/// Onboarding completion is persisted via `@AppStorage("hasCompletedOnboarding")`.
struct OnboardingView: View {

    // MARK: - App Storage

    /// Whether the user has completed the onboarding flow.
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    /// The selected use cases as a comma-separated string.
    @AppStorage("selectedUseCase") private var selectedUseCase: String = ""

    // MARK: - View Model

    /// The shared onboarding view model managing all screen state.
    @State private var viewModel = OnboardingViewModel()

    // MARK: - Body

    var body: some View {
        TabView(selection: $viewModel.currentPage) {
            // Screen 1 — Welcome
            WelcomeView(
                viewModel: viewModel,
                onGetStarted: { viewModel.nextPage() },
                onSkip: { viewModel.skip() }
            )
            .tag(0)

            // Screen 2 — Use Case Selection
            UseCaseSelectionView(
                viewModel: viewModel,
                onContinue: { viewModel.nextPage() },
                onSkip: { viewModel.skip() }
            )
            .tag(1)

            // Screen 3 — Branding Setup
            BrandingSetupView(
                viewModel: viewModel,
                onComplete: { hasCompletedOnboarding = true },
                onSkip: {
                    // Even when skipping branding, we mark onboarding complete
                    // with a default empty profile
                    viewModel.skip()
                }
            )
            .tag(2)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .ignoresSafeArea(.keyboard)
        .onAppear {
            // Ensure we start fresh on page 0
            viewModel.currentPage = 0
        }
    }
}

// MARK: - Preview

#Preview("Full Onboarding Flow") {
    OnboardingView()
        .modelContainer(for: [
            UserProfile.self,
            InspectionReport.self,
            InspectionArea.self,
            InspectionIssue.self,
            IssuePhoto.self
        ], inMemory: true)
}

#Preview("Full Onboarding Flow - Dark") {
    OnboardingView()
        .modelContainer(for: [
            UserProfile.self,
            InspectionReport.self,
            InspectionArea.self,
            InspectionIssue.self,
            IssuePhoto.self
        ], inMemory: true)
        .preferredColorScheme(.dark)
}
