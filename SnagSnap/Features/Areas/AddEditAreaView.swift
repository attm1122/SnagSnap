// SnagSnap
// AddEditAreaView.swift
//
// Sheet/form for adding or editing an inspection area within a report.

import SwiftUI
import SwiftData

// MARK: - AddEditAreaViewModel

/// View model managing the state and logic for the Add/Edit Area form.
@Observable
final class AddEditAreaViewModel {

    // MARK: - Form State

    var name: String = ""
    var notes: String = ""
    var showValidationError: Bool = false

    // MARK: - Dependencies

    private let area: InspectionArea?
    private let report: InspectionReport
    private let modelContext: ModelContext
    private let onComplete: () -> Void

    // MARK: - Computed Properties

    var isEditing: Bool { area != nil }
    var navigationTitle: String { isEditing ? "Edit Area" : "Add Area" }
    var isNameValid: Bool { !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    var canSave: Bool { isNameValid }

    // MARK: - Initialization

    /// Creates a view model for adding a new area or editing an existing one.
    /// - Parameters:
    ///   - area: The area to edit, or `nil` to create a new area.
    ///   - report: The report this area belongs to.
    ///   - modelContext: The SwiftData model context for persistence.
    ///   - onComplete: Closure called when the form is dismissed after save or cancel.
    init(
        area: InspectionArea? = nil,
        report: InspectionReport,
        modelContext: ModelContext,
        onComplete: @escaping () -> Void
    ) {
        self.area = area
        self.report = report
        self.modelContext = modelContext
        self.onComplete = onComplete

        if let area = area {
            self.name = area.name
            self.notes = area.notes ?? ""
        }
    }

    // MARK: - Actions

    /// Selects a suggested name, prepending it to any existing text.
    func selectSuggestedName(_ suggestedName: String) {
        name = suggestedName
    }

    /// Saves the area, either creating a new one or updating the existing one.
    func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            showValidationError = true
            return
        }

        if let area = area {
            // Update existing area
            area.name = trimmedName
            area.notes = notes.isEmpty ? nil : notes
            area.updatedAt = Date()
        } else {
            // Create new area
            let newArea = InspectionArea(name: trimmedName, notes: notes.isEmpty ? nil : notes)
            modelContext.insert(newArea)
            newArea.report = report

            if report.areas == nil {
                report.areas = []
            }
            report.areas?.append(newArea)
            report.updatedAt = Date()
        }

        do {
            try modelContext.save()
            onComplete()
        } catch {
            print("Failed to save area: \(error.localizedDescription)")
            showValidationError = true
        }
    }

    /// Cancels the form without saving.
    func cancel() {
        onComplete()
    }
}

// MARK: - AddEditAreaView

/// Sheet/form for adding or editing an inspection area.
struct AddEditAreaView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // MARK: - Properties

    private let area: InspectionArea?
    private let report: InspectionReport

    // MARK: - Local State

    @State private var viewModel: AddEditAreaViewModel?

    // MARK: - Initialization

    init(area: InspectionArea? = nil, report: InspectionReport) {
        self.area = area
        self.report = report
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                nameSection
                notesSection
            }
            .navigationTitle(viewModel?.navigationTitle ?? "Area")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel?.cancel()
                        dismiss()
                    }
                    .foregroundStyle(Theme.primary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel?.save()
                        dismiss()
                    }
                    .disabled(!(viewModel?.canSave ?? false))
                    .foregroundStyle(viewModel?.canSave ?? false ? Theme.primary : Theme.secondaryLabel)
                    .font(.body.weight(.semibold))
                }
            }
            .onAppear {
                viewModel = AddEditAreaViewModel(
                    area: area,
                    report: report,
                    modelContext: modelContext,
                    onComplete: { }
                )
            }
        }
    }

    // MARK: - Name Section

    @ViewBuilder
    private var nameSection: some View {
        Section("Area Name") {
            TextField("e.g. Kitchen, Master Bedroom", text: Binding(
                get: { viewModel?.name ?? "" },
                set: { viewModel?.name = $0 }
            ))
            .font(.body)
            .autocorrectionDisabled()

            if viewModel?.showValidationError ?? false {
                Text("Area name is required")
                    .font(.caption)
                    .foregroundStyle(Theme.error)
            }

            suggestedNamesGrid
        }
    }

    // MARK: - Suggested Names Grid

    @ViewBuilder
    private var suggestedNamesGrid: some View {
        let columns = [
            GridItem(.adaptive(minimum: 90), spacing: Theme.spacingS)
        ]

        LazyVGrid(columns: columns, spacing: Theme.spacingS) {
            ForEach(InspectionArea.suggestedNames, id: \.self) { suggestedName in
                SuggestedNameChip(
                    name: suggestedName,
                    isSelected: (viewModel?.name ?? "") == suggestedName
                ) {
                    viewModel?.selectSuggestedName(suggestedName)
                }
            }
        }
        .padding(.top, Theme.spacingS)
    }

    // MARK: - Notes Section

    @ViewBuilder
    private var notesSection: some View {
        Section("Notes") {
            TextEditor(text: Binding(
                get: { viewModel?.notes ?? "" },
                set: { viewModel?.notes = $0 }
            ))
            .font(.body)
            .frame(minHeight: 100)
        }
    }
}

// MARK: - SuggestedNameChip

/// A tappable chip representing a suggested area name.
private struct SuggestedNameChip: View {
    let name: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(name)
                .font(.subheadline.weight(.medium))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .foregroundStyle(isSelected ? .white : Theme.primary)
                .padding(.horizontal, Theme.spacingM)
                .padding(.vertical, Theme.spacingS)
                .frame(maxWidth: .infinity)
                .background(isSelected ? Theme.primary : Theme.primary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMedium, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("Add Area") {
    let container = try! PreviewContainer()
    let report = container.sampleReport

    return AddEditAreaView(report: report)
        .modelContainer(container.container)
}

#Preview("Edit Area") {
    let container = try! PreviewContainer()
    let report = container.sampleReport
    let area = report.areas!.first!

    return AddEditAreaView(area: area, report: report)
        .modelContainer(container.container)
}

// MARK: - Preview Helpers

private struct PreviewContainer {
    let container: ModelContainer
    let sampleReport: InspectionReport

    init() throws {
        let schema = Schema([InspectionReport.self, InspectionArea.self, InspectionIssue.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])

        let context = ModelContext(container)
        sampleReport = InspectionReport(
            title: "Sample Report",
            propertyName: "123 Main St",
            propertyAddress: "123 Main Street, London",
            reportType: .snagging
        )
        context.insert(sampleReport)

        let kitchen = InspectionArea(name: "Kitchen", notes: "Main kitchen area")
        context.insert(kitchen)
        kitchen.report = sampleReport
        sampleReport.areas = [kitchen]

        try context.save()
    }
}
