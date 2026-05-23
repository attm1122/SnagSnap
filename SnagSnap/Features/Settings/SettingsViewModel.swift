import SwiftUI
import SwiftData
import StoreKit
import Observation

// MARK: - Settings View Model

@Observable
final class SettingsViewModel {

    // MARK: Dependencies

    private let storeKitService = StoreKitService.shared
    private let entitlementManager = EntitlementManager.shared
    private let modelContext: ModelContext

    // MARK: Profile State

    var companyName: String = ""
    var inspectorName: String = ""
    var phone: String = ""
    var email: String = ""
    var profileSavedMessage: String?
    var showProfileSaved = false

    // MARK: Subscription State

    var isRestoring = false
    var showRestoreAlert = false
    var restoreMessage: String?

    // MARK: Default Export Settings (AppStorage-backed)

    @ObservationIgnored
    @AppStorage("includeCoverPage") var includeCoverPage: Bool = true

    @ObservationIgnored
    @AppStorage("includeSummary") var includeSummary: Bool = true

    @ObservationIgnored
    @AppStorage("includeTimestamps") var includeTimestamps: Bool = true

    @ObservationIgnored
    @AppStorage("defaultInspectorName") var defaultInspectorName: String = ""

    // MARK: Computed Properties

    var subscriptionState: SubscriptionState {
        storeKitService.subscriptionState
    }

    var isPro: Bool {
        storeKitService.isPro
    }

    var monthlyReportCount: Int {
        entitlementManager.monthlyReportCount
    }

    var remainingFreeReports: Int {
        entitlementManager.remainingFreeReports
    }

    var planDisplayName: String {
        storeKitService.subscriptionState.displayName
    }

    var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadProfile()
    }

    // MARK: - Profile Management

    func loadProfile() {
        let descriptor = FetchDescriptor<UserProfile>()

        if let profile = try? modelContext.fetch(descriptor).first {
            companyName = profile.companyName
            inspectorName = profile.inspectorName
            phone = profile.phone ?? ""
            email = profile.email ?? ""
        } else {
            // No existing profile — create a default one
            let newProfile = UserProfile(
                companyName: "",
                inspectorName: "",
                phone: nil,
                email: nil
            )
            modelContext.insert(newProfile)
            try? modelContext.save()
        }
    }

    func saveProfile() {
        let descriptor = FetchDescriptor<UserProfile>()

        if let profile = try? modelContext.fetch(descriptor).first {
            profile.companyName = companyName
            profile.inspectorName = inspectorName
            profile.phone = phone.isEmpty ? nil : phone
            profile.email = email.isEmpty ? nil : email
        } else {
            let profile = UserProfile(
                companyName: companyName,
                inspectorName: inspectorName,
                phone: phone.isEmpty ? nil : phone,
                email: email.isEmpty ? nil : email
            )
            modelContext.insert(profile)
        }

        do {
            try modelContext.save()
            profileSavedMessage = "Profile saved successfully"
            showProfileSaved = true
        } catch {
            profileSavedMessage = "Failed to save profile: \(error.localizedDescription)"
            showProfileSaved = true
        }
    }

    // MARK: - Subscription Actions

    func restorePurchases() async {
        isRestoring = true
        defer { isRestoring = false }

        let success = await storeKitService.restorePurchases()

        if success {
            restoreMessage = "Purchases restored successfully"
        } else {
            restoreMessage = "No previous purchases found to restore"
        }
        showRestoreAlert = true
    }

    func dismissRestoreAlert() {
        showRestoreAlert = false
        restoreMessage = nil
    }

    func dismissProfileSaved() {
        showProfileSaved = false
        profileSavedMessage = nil
    }
}
