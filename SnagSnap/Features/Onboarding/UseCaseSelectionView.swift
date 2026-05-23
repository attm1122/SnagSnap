// SnagSnap
// UseCaseSelectionView.swift
//
// Screen 2 of the onboarding flow — Use case selection.

import SwiftUI

// MARK: - UseCaseSelectionView

/// The second onboarding screen where the user selects their intended use cases.
///
/// Presents a scrollable grid of selectable cards, each with an SF Symbol icon
/// and label. Multiple selections are allowed. A continue button at the bottom
/// is enabled once at least one option is selected.
struct UseCaseSelectionView: View {

    // MARK: - Properties

    /// The shared onboarding view model.
    let viewModel: OnboardingViewModel

    /// Callback invoked when the user taps "Continue".
    let onContinue: () -> Void

    /// Callback invoked when the user taps "Skip".
    let onSkip: () -> Void

    // MARK: - Body

    var body: some View {
        ZStack {
            Theme.groupedBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header with skip button
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

                // Title section
                VStack(spacing: Theme.spacingS) {
                    Text("What will you use SnagSnap for?")
                        .font(Theme.fontTitle)
                        .foregroundStyle(Theme.label)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Theme.spacingL)

                    Text("Select all that apply")
                        .font(Theme.fontCallout)
                        .foregroundStyle(Theme.secondaryLabel)
                }
                .padding(.horizontal, Theme.spacingXL)

                // Use case grid
                ScrollView(showsIndicators: false) {
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: Theme.spacingM),
                            GridItem(.flexible(), spacing: Theme.spacingM)
                        ],
                        spacing: Theme.spacingM
                    ) {
                        ForEach(viewModel.useCaseOptions) { option in
                            UseCaseCard(
                                option: option,
                                isSelected: viewModel.selectedUseCases.contains(option.rawValue)
                            ) {
                                viewModel.toggleUseCase(option.rawValue)
                            }
                        }
                    }
                    .padding(.horizontal, Theme.spacingXL)
                    .padding(.top, Theme.spacingL)
                }

                // Bottom action area
                VStack(spacing: Theme.spacingL) {
                    SSButton(
                        "Continue",
                        style: .primary,
                        icon: "arrow.right",
                        isDisabled: !viewModel.canContinueFromUseCases,
                        isFullWidth: true,
                        action: onContinue
                    )

                    // Page indicator
                    HStack(spacing: Theme.spacingS) {
                        ForEach(0..<viewModel.totalPages, id: \.self) { index in
                            Capsule()
                                .fill(index == 1 ? Theme.primary : Theme.primary.opacity(0.2))
                                .frame(width: index == 1 ? 20 : 8, height: 8)
                                .animation(.easeInOut(duration: 0.25), value: viewModel.currentPage)
                        }
                    }
                }
                .padding(.horizontal, Theme.spacingXL)
                .padding(.vertical, Theme.spacingXL)
            }
        }
    }
}

// MARK: - UseCaseCard

/// A single selectable card representing a use case option.
///
/// Displays an SF Symbol icon, title, and a checkmark indicator when selected.
/// Uses the shared SSCard container with dynamic border styling.
private struct UseCaseCard: View {

    let option: UseCaseOption
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: Theme.spacingM) {
                ZStack {
                    RoundedRectangle(cornerRadius: Theme.radiusMedium, style: .continuous)
                        .fill(isSelected ? Theme.primary.opacity(0.12) : Theme.secondaryBackground)
                        .frame(width: 56, height: 56)

                    Image(systemName: option.icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(isSelected ? Theme.primary : Theme.secondaryLabel)
                }

                Text(option.title)
                    .font(Theme.fontCallout)
                    .foregroundStyle(isSelected ? Theme.label : Theme.secondaryLabel)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)

                // Checkmark indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(isSelected ? Theme.primary : Theme.separator)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.spacingL)
            .padding(.horizontal, Theme.spacingS)
            .background(
                RoundedRectangle(cornerRadius: Theme.radiusLarge, style: .continuous)
                    .fill(Theme.background)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radiusLarge, style: .continuous)
                    .stroke(
                        isSelected ? Theme.primary : Theme.separator,
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Preview

#Preview("Use Case Selection") {
    let vm = OnboardingViewModel()
    vm.selectedUseCases = ["rental", "snagging"]
    return UseCaseSelectionView(
        viewModel: vm,
        onContinue: {},
        onSkip: {}
    )
}

#Preview("Use Case Selection - Empty") {
    let vm = OnboardingViewModel()
    return UseCaseSelectionView(
        viewModel: vm,
        onContinue: {},
        onSkip: {}
    )
}

#Preview("Use Case Selection - Dark") {
    let vm = OnboardingViewModel()
    vm.selectedUseCases = ["airbnb", "cleaning", "maintenance"]
    return UseCaseSelectionView(
        viewModel: vm,
        onContinue: {},
        onSkip: {}
    )
    .preferredColorScheme(.dark)
}
