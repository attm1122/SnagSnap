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
    var exportErrorMessage: String?
    var showExportError = false

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

    // MARK: - Data Export

    func makeDataExportFile() throws -> URL {
        let reports = try modelContext.fetch(FetchDescriptor<InspectionReport>())
        let profiles = try modelContext.fetch(FetchDescriptor<UserProfile>())

        let payload = AppDataExport(
            exportedAt: Date(),
            appVersion: appVersion,
            profiles: profiles.map(ProfileExport.init),
            reports: reports.map(ReportExport.init)
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let data = try encoder.encode(payload)
        let filename = "SnagSnap-Export-\(Self.exportDateFormatter.string(from: Date())).json"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try data.write(to: url, options: .atomic)
        return url
    }

    func setExportError(_ error: Error) {
        exportErrorMessage = error.localizedDescription
        showExportError = true
    }

    func dismissExportError() {
        exportErrorMessage = nil
        showExportError = false
    }

    private static let exportDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HHmmss"
        return formatter
    }()
}

private struct AppDataExport: Encodable {
    let exportedAt: Date
    let appVersion: String
    let profiles: [ProfileExport]
    let reports: [ReportExport]
}

private struct ProfileExport: Encodable {
    let companyName: String
    let inspectorName: String
    let phone: String?
    let email: String?

    init(_ profile: UserProfile) {
        companyName = profile.companyName
        inspectorName = profile.inspectorName
        phone = profile.phone
        email = profile.email
    }
}

private struct ReportExport: Encodable {
    let id: UUID
    let title: String
    let propertyName: String
    let propertyAddress: String
    let reportType: String
    let status: String
    let clientName: String?
    let inspectorName: String?
    let generalNotes: String?
    let inspectionDate: Date
    let createdAt: Date
    let updatedAt: Date
    let lastExportedAt: Date?
    let areas: [AreaExport]
    let issues: [IssueExport]

    init(_ report: InspectionReport) {
        id = report.id
        title = report.title
        propertyName = report.propertyName
        propertyAddress = report.propertyAddress
        reportType = report.reportType.displayName
        status = report.status.displayName
        clientName = report.clientName
        inspectorName = report.inspectorName
        generalNotes = report.generalNotes
        inspectionDate = report.inspectionDate
        createdAt = report.createdAt
        updatedAt = report.updatedAt
        lastExportedAt = report.lastExportedAt
        areas = (report.areas ?? []).map(AreaExport.init)
        issues = (report.issues ?? []).map(IssueExport.init)
    }
}

private struct AreaExport: Encodable {
    let id: UUID
    let name: String
    let notes: String?
    let createdAt: Date
    let updatedAt: Date

    init(_ area: InspectionArea) {
        id = area.id
        name = area.name
        notes = area.notes
        createdAt = area.createdAt
        updatedAt = area.updatedAt
    }
}

private struct IssueExport: Encodable {
    let id: UUID
    let title: String
    let notes: String?
    let severity: String
    let status: String
    let areaName: String?
    let createdAt: Date
    let updatedAt: Date
    let photos: [PhotoExport]

    init(_ issue: InspectionIssue) {
        id = issue.id
        title = issue.title
        notes = issue.notes
        severity = issue.severity.displayName
        status = issue.status.displayName
        areaName = issue.area?.name
        createdAt = issue.createdAt
        updatedAt = issue.updatedAt
        photos = (issue.photos ?? []).map(PhotoExport.init)
    }
}

private struct PhotoExport: Encodable {
    let id: UUID
    let caption: String?
    let includeInReport: Bool
    let hasAnnotation: Bool
    let createdAt: Date
    let updatedAt: Date

    init(_ photo: IssuePhoto) {
        id = photo.id
        caption = photo.caption
        includeInReport = photo.includeInReport
        hasAnnotation = photo.hasAnnotation
        createdAt = photo.createdAt
        updatedAt = photo.updatedAt
    }
}
