// SnagSnap
// CreateReportView.swift
//
// Form for creating a new inspection report with validation and paywall gating.

import SwiftUI
import SwiftData

// MARK: - CreateReportViewModel

@Observable
final class CreateReportViewModel {

    // MARK: - Form State

    var title: String = ""
    var propertyName: String = ""
    var propertyAddress: String = ""
    var inspectionDate: Date = Date()
    var reportType: ReportType = .general
    var clientName: String = ""
    var inspectorName: String = ""
    var generalNotes: String = ""
    var showValidationErrors: Bool = false

    // MARK: - Dependencies

    private let modelContext: ModelContext
    private let onComplete: (InspectionReport) -> Void

    // MARK: - Computed Properties

    var isTitleValid: Bool { !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    var isPropertyNameValid: Bool { !propertyName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    var isPropertyAddressValid: Bool { !propertyAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    var canCreate: Bool {
        isTitleValid && isPropertyNameValid && isPropertyAddressValid
    }

    // MARK: - Initialization

    init(
        modelContext: ModelContext,
        prefilledInspectorName: String = "",
        onComplete: @escaping (InspectionReport) -> Void
    ) {
        self.modelContext = modelContext
        self.onComplete = onComplete
        self.inspectorName = prefilledInspectorName
    }

    // MARK: - Actions

    /// Creates a new inspection report and persists it.
    func createReport() -> InspectionReport? {
        showValidationErrors = true

        guard canCreate else { return nil }

        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedProperty = propertyName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAddress = propertyAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedClient = clientName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedInspector = inspectorName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNotes = generalNotes.trimmingCharacters(in: .whitespacesAndNewlines)

        let report = InspectionReport(
            title: trimmedTitle,
            propertyName: trimmedProperty,
            propertyAddress: trimmedAddress,
            reportType: reportType,
            clientName: trimmedClient.isEmpty ? nil : trimmedClient,
            inspectorName: trimmedInspector.isEmpty ? nil : trimmedInspector,
            generalNotes: trimmedNotes.isEmpty ? nil : trimmedNotes,
            inspectionDate: inspectionDate
        )

        modelContext.insert(report)

        do {
            try modelContext.save()
            EntitlementManager.shared.incrementReportCount()
            onComplete(report)
            return report
        } catch {
            print("Failed to save report: \(error.localizedDescription)")
            return nil
        }
    }
}

// MARK: - CreateReportView

/// Form view for creating a new inspection report.
struct CreateReportView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - State

    @State private var viewModel: CreateReportViewModel?
    @State private var showPaywall = false
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var shakeValidation = false

    // MARK: - Injected Dependencies

    private let injectedModelContext: ModelContext?
    var onComplete: ((InspectionReport) -> Void)?

    // MARK: - Initialization

    init(modelContext: ModelContext? = nil, onComplete: ((InspectionReport) -> Void)? = nil) {
        self.injectedModelContext = modelContext
        self.onComplete = onComplete
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                // Paywall banner (if applicable)
                if !EntitlementManager.shared.canCreateNewReport() {
                    paywallSection
                        .entryAnimation(delay: 0.0)
                }

                // Required fields
                requiredFieldsSection
                    .entryAnimation(delay: 0.05)

                // Report type
                reportTypeSection
                    .entryAnimation(delay: 0.1)

                // Optional fields
                optionalFieldsSection
                    .entryAnimation(delay: 0.15)

                // Notes
                notesSection
                    .entryAnimation(delay: 0.2)
            }
            .scrollContentBackground(.hidden)
            .background(
                LinearGradient(
                    colors: [Theme.blueSurfaceStrong, Theme.background, Theme.background],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .tint(Theme.primary)
            .navigationTitle("New Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.blueSurfaceStrong, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(.animated(haptic: .light))
                    .foregroundStyle(Theme.primary)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        if viewModel?.createReport() != nil {
                            HapticService.shared.play(.success)
                            toastMessage = "Report created"
                            showToast = true
                            dismiss()
                        } else {
                            HapticService.shared.play(.warning)
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.3)) {
                                shakeValidation = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                shakeValidation = false
                            }
                        }
                    }
                    .buttonStyle(.animated(haptic: .medium))
                    .disabled(!(viewModel?.canCreate ?? false) || !EntitlementManager.shared.canCreateNewReport())
                    .foregroundStyle(
                        (viewModel?.canCreate ?? false) && EntitlementManager.shared.canCreateNewReport()
                        ? Theme.primary
                        : Theme.secondaryLabel
                    )
                    .font(.body.weight(.semibold))
                    .accessibilityLabel("Create report")
                    .offset(x: shakeValidation ? 10 : 0)
                }
            }
            .onAppear {
                // Prefill inspector name from UserProfile if available
                let inspectorName = fetchUserProfileInspectorName()
                let ctx = injectedModelContext ?? modelContext
                viewModel = CreateReportViewModel(
                    modelContext: ctx,
                    prefilledInspectorName: inspectorName,
                    onComplete: { [self] report in
                        self.onComplete?(report)
                    }
                )
            }
            .dismissKeyboardOnTap()
            .toast(isPresented: $showToast, message: toastMessage, style: .success, duration: 2.0)
        }
    }

    // MARK: - Paywall Section

    private var paywallSection: some View {
        Section {
            VStack(spacing: Theme.spacingM) {
                HStack(spacing: Theme.spacingS) {
                    Image(systemName: "lock.fill")
                        .font(.title2)
                        .foregroundStyle(Theme.warning)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Report Limit Reached")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.primary)

                        Text("Upgrade to Pro for unlimited reports.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }

                SSButton(
                    "Upgrade to Pro",
                    style: .primary,
                    icon: "crown.fill",
                    isFullWidth: true
                ) {
                    HapticService.shared.play(.medium)
                    showPaywall = true
                }
                .accessibilityLabel("Upgrade to Pro")
            }
            .padding(.vertical, Theme.spacingS)
        }
        .listRowBackground(Theme.warning.opacity(0.08))
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    // MARK: - Required Fields Section

    private var requiredFieldsSection: some View {
        Section {
            // Report Title
            VStack(alignment: .leading, spacing: 4) {
                TextField("Report Title", text: Binding(
                    get: { viewModel?.title ?? "" },
                    set: { viewModel?.title = $0 }
                ))
                .font(.body)
                .autocorrectionDisabled()

                if (viewModel?.showValidationErrors ?? false) && !(viewModel?.isTitleValid ?? true) {
                    Text("Report title is required")
                        .font(.caption)
                        .foregroundStyle(Theme.error)
                }
            }

            // Property Name
            VStack(alignment: .leading, spacing: 4) {
                TextField("Property Name", text: Binding(
                    get: { viewModel?.propertyName ?? "" },
                    set: { viewModel?.propertyName = $0 }
                ))
                .font(.body)
                .autocorrectionDisabled()

                if (viewModel?.showValidationErrors ?? false) && !(viewModel?.isPropertyNameValid ?? true) {
                    Text("Property name is required")
                        .font(.caption)
                        .foregroundStyle(Theme.error)
                }
            }

            // Property Address
            VStack(alignment: .leading, spacing: 4) {
                TextField("Property Address", text: Binding(
                    get: { viewModel?.propertyAddress ?? "" },
                    set: { viewModel?.propertyAddress = $0 }
                ), axis: .vertical)
                .font(.body)

                if (viewModel?.showValidationErrors ?? false) && !(viewModel?.isPropertyAddressValid ?? true) {
                    Text("Property address is required")
                        .font(.caption)
                        .foregroundStyle(Theme.error)
                }
            }

            // Inspection Date
            DatePicker(
                "Inspection Date",
                selection: Binding(
                    get: { viewModel?.inspectionDate ?? Date() },
                    set: { viewModel?.inspectionDate = $0 }
                ),
                displayedComponents: .date
            )
            .font(.body)
        } header: {
            Text("Required Information")
        } footer: {
            Text("These fields are required to create a report.")
                .font(.caption)
        }
        .listRowBackground(Theme.cardBackground)
    }

    // MARK: - Report Type Section

    private var reportTypeSection: some View {
        Section("Report Type") {
            Picker("Type", selection: Binding(
                get: { viewModel?.reportType ?? .general },
                set: { newValue in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        viewModel?.reportType = newValue
                    }
                }
            )) {
                ForEach(ReportType.allCases) { type in
                    HStack(spacing: Theme.spacingS) {
                        Image(systemName: type.icon)
                            .foregroundStyle(Theme.primary)
                            .frame(width: 24)
                        Text(type.displayName)
                    }
                    .tag(type)
                }
            }
            .pickerStyle(.navigationLink)
        }
        .listRowBackground(Theme.cardBackground)
    }

    // MARK: - Optional Fields Section

    private var optionalFieldsSection: some View {
        Section("Optional Details") {
            TextField("Client / Tenant Name", text: Binding(
                get: { viewModel?.clientName ?? "" },
                set: { viewModel?.clientName = $0 }
            ))
            .font(.body)

            TextField("Inspector Name", text: Binding(
                get: { viewModel?.inspectorName ?? "" },
                set: { viewModel?.inspectorName = $0 }
            ))
            .font(.body)
            .autocorrectionDisabled()
        }
        .listRowBackground(Theme.cardBackground)
    }

    // MARK: - Notes Section

    private var notesSection: some View {
        Section("General Notes") {
            TextEditor(text: Binding(
                get: { viewModel?.generalNotes ?? "" },
                set: { viewModel?.generalNotes = $0 }
            ))
            .font(.body)
            .frame(minHeight: 100)
        }
        .listRowBackground(Theme.cardBackground)
    }

    // MARK: - Helpers

    private func fetchUserProfileInspectorName() -> String {
        let descriptor = FetchDescriptor<UserProfile>()
        let profiles = (try? modelContext.fetch(descriptor)) ?? []
        return profiles.first?.inspectorName ?? ""
    }
}

// MARK: - Feature Row

private struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: Theme.spacingS) {
            Image(systemName: icon)
                .foregroundStyle(Theme.primary)
                .frame(width: 28)
            Text(text)
                .font(.body)
                .foregroundStyle(.primary)
        }
    }
}

// MARK: - Preview

#Preview("Create Report") {
    let schema = Schema([InspectionReport.self, InspectionArea.self, InspectionIssue.self, IssuePhoto.self, UserProfile.self])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [config])

    return CreateReportView()
        .modelContainer(container)
}
