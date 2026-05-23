import SwiftUI
import SwiftData

/// The main app entry point for SnagSnap.
///
/// Handles app-level setup including:
/// - SwiftData model container configuration
/// - Onboarding state routing
/// - Scene/window management
@main
struct SnagSnapApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("selectedUseCase") private var selectedUseCase: String = ""

    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    MainTabView()
                } else {
                    OnboardingView()
                }
            }
            .modelContainer(for: [
                UserProfile.self,
                InspectionReport.self,
                InspectionArea.self,
                InspectionIssue.self,
                IssuePhoto.self
            ])
        }
    }
}
