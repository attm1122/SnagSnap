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
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.spacingL) {
                if !EntitlementManager.shared.canCreateNewReport() {
                    paywallSection
                        .entryAnimation(delay: 0.0)
                }

                requiredFieldsSection
                    .entryAnimation(delay: 0.05)

                reportTypeSection
                    .entryAnimation(delay: 0.1)

                optionalFieldsSection
                    .entryAnimation(delay: 0.15)

                notesSection
                    .entryAnimation(delay: 0.2)
            }
            .padding(.horizontal, Theme.spacingM)
            .padding(.top, Theme.spacingXL)
            .padding(.bottom, Theme.spacingXXL)
        }
        .background(
            LinearGradient(
                colors: [
                    Theme.blueSurfaceStrong,
                    Theme.background,
                    Theme.background
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .tint(Theme.primary)
        .foregroundStyle(Theme.ink)
        .navigationTitle("New Report")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.blueSurfaceStrong, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
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
                        if onComplete == nil {
                            dismiss()
                        }
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

    // MARK: - Paywall Section

    private var paywallSection: some View {
        SSCard(background: Theme.warning.opacity(0.08), borderColor: Theme.warning.opacity(0.25)) {
            VStack(spacing: Theme.spacingM) {
                HStack(spacing: Theme.spacingS) {
                    Image(systemName: "lock.fill")
                        .font(.title2)
                        .foregroundStyle(Theme.warning)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Report Limit Reached")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(Theme.ink)

                        Text("Upgrade to Pro for unlimited reports.")
                            .font(.subheadline)
                            .foregroundStyle(Theme.secondaryLabel)
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
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    // MARK: - Required Fields Section

    private var requiredFieldsSection: some View {
        FormCard(
            title: "Required Information",
            footer: "These fields are required to create a report."
        ) {
            VStack(spacing: Theme.spacingM) {
                RequiredTextInput(
                    title: "Report Title",
                    placeholder: "e.g. Final inspection - Unit 4",
                    text: Binding(
                    get: { viewModel?.title ?? "" },
                    set: { viewModel?.title = $0 }
                    ),
                    errorMessage: (viewModel?.showValidationErrors ?? false) && !(viewModel?.isTitleValid ?? true)
                    ? "Report title is required"
                    : nil
                )

                RequiredTextInput(
                    title: "Property Name",
                    placeholder: "e.g. Harbour View Apartments",
                    text: Binding(
                    get: { viewModel?.propertyName ?? "" },
                    set: { viewModel?.propertyName = $0 }
                    ),
                    errorMessage: (viewModel?.showValidationErrors ?? false) && !(viewModel?.isPropertyNameValid ?? true)
                    ? "Property name is required"
                    : nil
                )

                RequiredTextInput(
                    title: "Property Address",
                    placeholder: "Street address",
                    text: Binding(
                    get: { viewModel?.propertyAddress ?? "" },
                    set: { viewModel?.propertyAddress = $0 }
                    ),
                    axis: .vertical,
                    errorMessage: (viewModel?.showValidationErrors ?? false) && !(viewModel?.isPropertyAddressValid ?? true)
                    ? "Property address is required"
                    : nil
                )

                HStack(spacing: Theme.spacingM) {
                    Label("Inspection Date", systemImage: Theme.iconCalendar)
                        .font(Theme.callout)
                        .foregroundStyle(Theme.ink)

                    Spacer()

                    DatePicker(
                        "Inspection Date",
                        selection: Binding(
                            get: { viewModel?.inspectionDate ?? Date() },
                            set: { viewModel?.inspectionDate = $0 }
                        ),
                        displayedComponents: .date
                    )
                    .labelsHidden()
                    .font(Theme.body)
                    .foregroundStyle(Theme.ink)
                }
                .padding(.horizontal, Theme.spacingM)
                .frame(minHeight: 52)
                .background(Theme.background)
                .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMedium, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.radiusMedium, style: .continuous)
                        .stroke(Theme.separator, lineWidth: 1)
                )
            }
        }
    }

    // MARK: - Report Type Section

    private var reportTypeSection: some View {
        FormCard(title: "Report Type") {
            HStack(spacing: Theme.spacingM) {
                Image(systemName: viewModel?.reportType.icon ?? ReportType.general.icon)
                    .font(.title3)
                    .foregroundStyle(Theme.primary)
                    .frame(width: 40, height: 40)
                    .background(Theme.primaryLight, in: RoundedRectangle(cornerRadius: Theme.radiusMedium, style: .continuous))

                Picker("Type", selection: Binding(
                    get: { viewModel?.reportType ?? .general },
                    set: { newValue in
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            viewModel?.reportType = newValue
                        }
                    }
                )) {
                    ForEach(ReportType.allCases) { type in
                        Label(type.displayName, systemImage: type.icon)
                            .tag(type)
                    }
                }
                .pickerStyle(.navigationLink)
                .font(Theme.body)
                .foregroundStyle(Theme.ink)
            }
            .padding(.horizontal, Theme.spacingM)
            .frame(minHeight: 56)
            .background(Theme.background)
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMedium, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radiusMedium, style: .continuous)
                    .stroke(Theme.separator, lineWidth: 1)
            )
        }
    }

    // MARK: - Optional Fields Section

    private var optionalFieldsSection: some View {
        FormCard(title: "Optional Details") {
            VStack(spacing: Theme.spacingM) {
                RequiredTextInput(
                    title: "Client / Tenant Name",
                    placeholder: "Optional",
                    text: Binding(
                        get: { viewModel?.clientName ?? "" },
                        set: { viewModel?.clientName = $0 }
                    )
                )

                RequiredTextInput(
                    title: "Inspector Name",
                    placeholder: "Optional",
                    text: Binding(
                        get: { viewModel?.inspectorName ?? "" },
                        set: { viewModel?.inspectorName = $0 }
                    )
                )
            }
        }
    }

    // MARK: - Notes Section

    private var notesSection: some View {
        FormCard(title: "General Notes") {
            ZStack(alignment: .topLeading) {
                if (viewModel?.generalNotes ?? "").isEmpty {
                    Text("Add context, access notes, or inspection scope.")
                        .font(Theme.body)
                        .foregroundStyle(Theme.tertiaryLabel)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 8)
                }

                TextEditor(text: Binding(
                    get: { viewModel?.generalNotes ?? "" },
                    set: { viewModel?.generalNotes = $0 }
                ))
                .font(Theme.body)
                .foregroundStyle(Theme.ink)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 132)
            }
            .padding(.horizontal, Theme.spacingM - 5)
            .padding(.vertical, Theme.spacingS)
            .background(Theme.background)
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMedium, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radiusMedium, style: .continuous)
                    .stroke(Theme.separator, lineWidth: 1)
            )
        }
    }

    // MARK: - Helpers

    private func fetchUserProfileInspectorName() -> String {
        let descriptor = FetchDescriptor<UserProfile>()
        let profiles = (try? modelContext.fetch(descriptor)) ?? []
        return profiles.first?.inspectorName ?? ""
    }
}

// MARK: - Form Components

private struct FormCard<Content: View>: View {
    let title: String
    let footer: String?
    @ViewBuilder let content: Content

    init(title: String, footer: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.footer = footer
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingS) {
            Text(title)
                .font(Theme.headline)
                .foregroundStyle(Theme.ink)
                .padding(.horizontal, Theme.spacingS)

            SSCard(
                padding: Theme.spacingM,
                cornerRadius: Theme.radiusLarge,
                shadowRadius: Theme.shadowRadiusMedium,
                shadowY: Theme.shadowYOffsetMedium,
                background: Theme.cardBackground,
                borderColor: Theme.separator.opacity(0.65)
            ) {
                content
            }

            if let footer {
                Text(footer)
                    .font(Theme.caption)
                    .foregroundStyle(Theme.secondaryLabel)
                    .padding(.horizontal, Theme.spacingS)
            }
        }
    }
}

private struct RequiredTextInput: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var axis: Axis = .horizontal
    var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingXS) {
            Text(title)
                .font(Theme.callout)
                .foregroundStyle(Theme.ink)

            TextField(
                "",
                text: $text,
                prompt: Text(placeholder).foregroundStyle(Theme.tertiaryLabel),
                axis: axis
            )
            .font(Theme.body)
            .foregroundStyle(Theme.ink)
            .tint(Theme.primary)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.words)
            .padding(.horizontal, Theme.spacingM)
            .frame(minHeight: axis == .vertical ? 64 : 52, alignment: .center)
            .background(Theme.background)
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMedium, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radiusMedium, style: .continuous)
                    .stroke(errorMessage == nil ? Theme.separator : Theme.error, lineWidth: errorMessage == nil ? 1 : 1.5)
            )

            if let errorMessage {
                Text(errorMessage)
                    .font(Theme.caption)
                    .foregroundStyle(Theme.error)
            }
        }
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
