import SwiftUI
import SwiftData
import Foundation

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

    init() {
        do {
            _ = try FileManager.default.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
        } catch {
            assertionFailure("Unable to prepare Application Support directory: \(error)")
        }
    }

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
