// SnagSnap
// BrandingSetupView.swift
//
// Screen 3 of the onboarding flow — Branding / profile setup.

import SwiftUI
import SwiftData

// MARK: - BrandingSetupView

/// The third and final onboarding screen for setting up report branding.
///
/// Collects the company/inspector name, phone, and email. Persists the data
/// to a SwiftData ``UserProfile`` and marks onboarding as complete.
struct BrandingSetupView: View {

    // MARK: - Properties

    /// The shared onboarding view model.
    @Bindable var viewModel: OnboardingViewModel

    /// The SwiftData model context for persisting the user profile.
    @Environment(\.modelContext) private var modelContext

    /// Callback invoked when the user completes onboarding.
    let onComplete: () -> Void

    /// Callback invoked when the user taps "Skip".
    let onSkip: () -> Void

    // MARK: - Body

    var body: some View {
        ZStack {
            Theme.groupedBackground
                .ignoresSafeArea()
                .dismissKeyboardOnTap()

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
                    Text("Set up your report branding")
                        .font(Theme.fontTitle)
                        .foregroundStyle(Theme.label)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Theme.spacingL)

                    Text("These details will appear on your PDF reports")
                        .font(Theme.fontCallout)
                        .foregroundStyle(Theme.secondaryLabel)
                }
                .padding(.horizontal, Theme.spacingXL)

                // Form fields
                ScrollView(showsIndicators: false) {
                    VStack(spacing: Theme.spacingL) {
                        // Company / Inspector Name
                        SSTextField(
                            "Company / Inspector Name",
                            placeholder: "e.g. Acme Property Inspections",
                            text: $viewModel.inspectorName,
                            icon: "person.fill",
                            errorMessage: viewModel.inspectorName.isEmpty
                                ? nil
                                : (viewModel.isNameValid ? nil : "Name is required")
                        )

                        // Phone number
                        SSTextField(
                            "Phone number",
                            placeholder: "+44 7700 900123",
                            text: $viewModel.phone,
                            icon: "phone.fill"
                        )
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)

                        // Email address
                        SSTextField(
                            "Email address",
                            placeholder: "inspector@example.com",
                            text: $viewModel.email,
                            icon: "envelope.fill"
                        )
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                    }
                    .padding(.horizontal, Theme.spacingXL)
                    .padding(.top, Theme.spacingXL)
                }

                Spacer()

                // Bottom action area
                VStack(spacing: Theme.spacingL) {
                    SSButton(
                        "Start First Report",
                        style: .primary,
                        icon: "checkmark",
                        isDisabled: !viewModel.canCompleteOnboarding,
                        isFullWidth: true,
                        action: {
                            HapticService.shared.play(.success)
                            viewModel.completeOnboarding(context: modelContext)
                            onComplete()
                        }
                    )
                    .accessibilityLabel("Start first report")

                    // Page indicator
                    HStack(spacing: Theme.spacingS) {
                        ForEach(0..<viewModel.totalPages, id: \.self) { index in
                            Capsule()
                                .fill(index == 2 ? Theme.primary : Theme.primary.opacity(0.2))
                                .frame(width: index == 2 ? 20 : 8, height: 8)
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

// MARK: - Preview

#Preview("Branding Setup") {
    let vm = OnboardingViewModel()
    return BrandingSetupView(
        viewModel: vm,
        onComplete: {},
        onSkip: {}
    )
    .modelContainer(for: UserProfile.self, inMemory: true)
}

#Preview("Branding Setup - Filled") {
    let vm = OnboardingViewModel()
    vm.inspectorName = "Jane Inspector"
    vm.companyName = "Premier Property Services"
    vm.phone = "+44 7700 900123"
    vm.email = "jane@premierprops.co.uk"
    return BrandingSetupView(
        viewModel: vm,
        onComplete: {},
        onSkip: {}
    )
    .modelContainer(for: UserProfile.self, inMemory: true)
}

#Preview("Branding Setup - Dark") {
    let vm = OnboardingViewModel()
    return BrandingSetupView(
        viewModel: vm,
        onComplete: {},
        onSkip: {}
    )
    .modelContainer(for: UserProfile.self, inMemory: true)
    .preferredColorScheme(.dark)
}
