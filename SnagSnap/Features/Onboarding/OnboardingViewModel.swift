// SnagSnap
// OnboardingViewModel.swift
//
// Manages all state, validation, and business logic for the onboarding flow.

import SwiftUI
import SwiftData

// MARK: - UseCaseOption

/// Represents a single selectable use case in the onboarding flow.
struct UseCaseOption: Identifiable, Hashable {
    let id = UUID()
    let icon: String
    let title: String
    let rawValue: String
}

// MARK: - OnboardingViewModel

/// View model managing the entire 3-screen onboarding flow.
///
/// Tracks current page, use case selections, form input, validation,
/// and handles persistence of onboarding completion and user profile creation.
@Observable
final class OnboardingViewModel {

    // MARK: - Page State

    /// Current onboarding page index (0, 1, or 2).
    var currentPage = 0

    /// Total number of onboarding pages.
    let totalPages = 3

    // MARK: - Use Case Selection

    /// Set of selected use case raw values.
    var selectedUseCases: Set<String> = []

    /// All available use case options presented on screen 2.
    let useCaseOptions: [UseCaseOption] = [
        UseCaseOption(icon: "house.fill", title: "Rental inspections", rawValue: "rental"),
        UseCaseOption(icon: "door.right.hand.open", title: "End-of-tenancy reports", rawValue: "end_of_tenancy"),
        UseCaseOption(icon: "bed.double.fill", title: "Airbnb turnovers", rawValue: "airbnb"),
        UseCaseOption(icon: "sparkles", title: "Cleaning reports", rawValue: "cleaning"),
        UseCaseOption(icon: "hammer.fill", title: "Building snag lists", rawValue: "snagging"),
        UseCaseOption(icon: "wrench.and.screwdriver.fill", title: "Maintenance reports", rawValue: "maintenance"),
        UseCaseOption(icon: "ellipsis.circle.fill", title: "Other", rawValue: "other")
    ]

    // MARK: - Branding Form (Screen 3)

    /// Company or inspector name entered by the user.
    var companyName = ""

    /// Inspector's name entered by the user.
    var inspectorName = ""

    /// Phone number entered by the user.
    var phone = ""

    /// Email address entered by the user.
    var email = ""

    // MARK: - Validation

    /// Whether the name field has any non-whitespace content.
    var isNameValid: Bool {
        !inspectorName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Whether at least one use case has been selected.
    var hasSelectedUseCase: Bool {
        !selectedUseCases.isEmpty
    }

    /// Use-case selection is optional; it tunes defaults but should not block activation.
    var canContinueFromUseCases: Bool {
        true
    }

    /// Branding details are optional and can be completed later in Settings.
    var canCompleteOnboarding: Bool {
        true
    }

    /// The selected use cases as a comma-separated string for AppStorage persistence.
    var selectedUseCaseString: String {
        selectedUseCases.sorted().joined(separator: ",")
    }

    // MARK: - Navigation Actions

    /// Advance to the next onboarding page with animation.
    func nextPage() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentPage = min(currentPage + 1, totalPages - 1)
        }
    }

    /// Go back to the previous onboarding page with animation.
    func previousPage() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentPage = max(currentPage - 1, 0)
        }
    }

    /// Skip directly to the last onboarding page.
    func skip() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentPage = totalPages - 1
        }
    }

    /// Jump to a specific page.
    func goToPage(_ page: Int) {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentPage = max(0, min(page, totalPages - 1))
        }
    }

    // MARK: - Use Case Actions

    /// Toggle a use case selection on or off.
    /// - Parameter rawValue: The raw value of the use case to toggle.
    func toggleUseCase(_ rawValue: String) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if selectedUseCases.contains(rawValue) {
                selectedUseCases.remove(rawValue)
            } else {
                selectedUseCases.insert(rawValue)
            }
        }
    }

    // MARK: - Completion

    /// Completes the onboarding flow by persisting use cases, creating a UserProfile,
    /// and marking onboarding as completed.
    ///
    /// - Parameter context: The SwiftData model context for inserting the profile.
    func completeOnboarding(context: ModelContext) {
        // Persist selected use cases as comma-separated string
        UserDefaults.standard.set(selectedUseCaseString, forKey: "selectedUseCase")

        let trimmedCompanyName = companyName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedInspectorName = inspectorName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPhone = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        // Create a profile only when the user supplied branding details.
        if !trimmedCompanyName.isEmpty || !trimmedInspectorName.isEmpty || !trimmedPhone.isEmpty || !trimmedEmail.isEmpty {
            let profile = UserProfile(
                companyName: trimmedCompanyName,
                inspectorName: trimmedInspectorName,
                phone: trimmedPhone.isEmpty ? nil : trimmedPhone,
                email: trimmedEmail.isEmpty ? nil : trimmedEmail
            )

            context.insert(profile)
            try? context.save()
        }

        // Mark onboarding as completed — triggers root view to switch to MainTabView
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }
}
