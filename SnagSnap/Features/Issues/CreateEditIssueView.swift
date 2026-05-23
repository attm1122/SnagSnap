// SnagSnap
// CreateEditIssueView.swift
//
// Full-screen form for creating or editing an inspection issue.

import SwiftUI
import SwiftData
import PhotosUI

// MARK: - CreateEditIssueViewModel

/// View model managing the state and logic for the Create/Edit Issue form.
@Observable
final class CreateEditIssueViewModel {

    // MARK: - Form State

    var title: String = ""
    var selectedAreaID: UUID?
    var severity: IssueSeverity = .medium
    var status: IssueStatus = .open
    var notes: String = ""
    var isSaving: Bool = false
    var showValidationError: Bool = false

    // MARK: - Photo State

    var isShowingCamera: Bool = false
    var isShowingPhotoPicker: Bool = false
    var photoItems: [PhotosPickerItem] = []
    var isProcessingPhotos: Bool = false
    var photoToAnnotate: IssuePhoto?
    var showPhotoAnnotation: Bool = false
    var photoToDelete: IssuePhoto?
    var showDeletePhotoConfirmation: Bool = false

    // MARK: - Dependencies

    private let issue: InspectionIssue?
    private let report: InspectionReport
    private let initialArea: InspectionArea?
    private let modelContext: ModelContext
    private let onComplete: () -> Void

    // MARK: - Computed Properties

    var isEditing: Bool { issue != nil }
    var navigationTitle: String { isEditing ? "Edit Issue" : "New Issue" }
    var isTitleValid: Bool { !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    var isAreaSelected: Bool { selectedAreaID != nil }
    var canSave: Bool { isTitleValid && isAreaSelected && !isSaving }

    var availableAreas: [InspectionArea] {
        report.areas ?? []
    }

    var selectedArea: InspectionArea? {
        guard let selectedAreaID = selectedAreaID else { return nil }
        return availableAreas.first { $0.id == selectedAreaID }
    }

    var currentPhotos: [IssuePhoto] {
        issue?.photos ?? []
    }

    // MARK: - Initialization

    /// Creates a view model for creating a new issue or editing an existing one.
    /// - Parameters:
    ///   - issue: The issue to edit, or `nil` to create a new issue.
    ///   - area: The default area to associate with the new issue.
    ///   - report: The report this issue belongs to.
    ///   - modelContext: The SwiftData model context for persistence.
    ///   - onComplete: Closure called when the form is dismissed.
    init(
        issue: InspectionIssue? = nil,
        area: InspectionArea?,
        report: InspectionReport,
        modelContext: ModelContext,
        onComplete: @escaping () -> Void
    ) {
        self.issue = issue
        self.report = report
        self.initialArea = area
        self.modelContext = modelContext
        self.onComplete = onComplete

        if let issue = issue {
            self.title = issue.title
            self.selectedAreaID = issue.area?.id
            self.severity = issue.severity
            self.status = issue.status
            self.notes = issue.notes ?? ""
        } else if let area = area {
            self.selectedAreaID = area.id
        }
    }

    // MARK: - Actions

    /// Saves the issue, either creating a new one or updating the existing one.
    func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty, let selectedAreaID = selectedAreaID else {
            showValidationError = true
            return
        }

        isSaving = true
        defer { isSaving = false }

        // Find the selected area in the current context
        let descriptor = FetchDescriptor<InspectionArea>(
            predicate: #Predicate { $0.id == selectedAreaID }
        )
        guard let targetArea = (try? modelContext.fetch(descriptor))?.first else {
            showValidationError = true
            return
        }

        if let issue = issue {
            // Update existing issue
            issue.title = trimmedTitle
            issue.notes = notes.isEmpty ? nil : notes
            issue.severity = severity
            issue.status = status
            issue.area = targetArea
            issue.updatedAt = Date()
            issue.report = report
        } else {
            // Create new issue
            let newIssue = InspectionIssue(
                title: trimmedTitle,
                notes: notes.isEmpty ? nil : notes,
                severity: severity,
                status: status
            )
            modelContext.insert(newIssue)
            newIssue.report = report
            newIssue.area = targetArea

            if report.issues == nil {
                report.issues = []
            }
            report.issues?.append(newIssue)
            targetArea.issues = (targetArea.issues ?? []) + [newIssue]
            report.updatedAt = Date()
        }

        do {
            try modelContext.save()
            onComplete()
        } catch {
            print("Failed to save issue: \(error.localizedDescription)")
            showValidationError = true
        }
    }

    /// Cancels the form without saving.
    func cancel() {
        onComplete()
    }

    // MARK: - Photo Actions

    /// Adds a newly captured photo to the issue.
    func addCapturedPhoto(image: UIImage) {
        Task { @MainActor in
            do {
                let paths = try FileStorageService.shared.saveImage(image)
                let newPhoto = IssuePhoto(
                    originalImagePath: paths.originalPath,
                    thumbnailImagePath: paths.thumbnailPath
                )
                modelContext.insert(newPhoto)

                if let issue = issue {
                    newPhoto.issue = issue
                    issue.photos = (issue.photos ?? []) + [newPhoto]
                    issue.updatedAt = Date()
                } else {
                    // Store temporarily — will be attached on save
                    // For now, insert into context and we'll need to attach after issue creation
                }

                try modelContext.save()
            } catch {
                print("Failed to save captured photo: \(error)")
            }
        }
    }

    /// Adds photos selected from the photo library.
    func addPhotosFromPicker(items: [PhotosPickerItem]) {
        isProcessingPhotos = true

        Task { @MainActor in
            defer { isProcessingPhotos = false }

            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    do {
                        let paths = try FileStorageService.shared.saveImage(uiImage)
                        let newPhoto = IssuePhoto(
                            originalImagePath: paths.originalPath,
                            thumbnailImagePath: paths.thumbnailPath
                        )
                        modelContext.insert(newPhoto)

                        if let issue = issue {
                            newPhoto.issue = issue
                            issue.photos = (issue.photos ?? []) + [newPhoto]
                            issue.updatedAt = Date()
                            try modelContext.save()
                        }
                    } catch {
                        print("Failed to save library photo: \(error)")
                    }
                }
            }
        }
    }

    /// Initiates annotation for a specific photo.
    func annotatePhoto(_ photo: IssuePhoto) {
        photoToAnnotate = photo
        showPhotoAnnotation = true
    }

    /// Marks a photo for deletion and shows confirmation.
    func requestDeletePhoto(_ photo: IssuePhoto) {
        photoToDelete = photo
        showDeletePhotoConfirmation = true
    }

    /// Deletes the confirmed photo.
    func confirmDeletePhoto() {
        guard let photo = photoToDelete else { return }

        if let issue = issue {
            issue.photos?.removeAll { $0.id == photo.id }
            issue.updatedAt = Date()
        }

        // Delete files
        try? FileStorageService.shared.deleteImage(at: photo.originalImagePath)
        try? FileStorageService.shared.deleteImage(at: photo.thumbnailImagePath)
        if let annotatedPath = photo.annotatedImagePath {
            try? FileStorageService.shared.deleteImage(at: annotatedPath)
        }

        modelContext.delete(photo)

        do {
            try modelContext.save()
        } catch {
            print("Failed to delete photo: \(error)")
        }

        photoToDelete = nil
    }
}

// MARK: - CreateEditIssueView

/// Full-screen form for creating or editing an inspection issue.
struct CreateEditIssueView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // MARK: - Properties

    private let issue: InspectionIssue?
    private let area: InspectionArea?
    private let report: InspectionReport

    // MARK: - View Model

    @State private var viewModel: CreateEditIssueViewModel?

    // MARK: - Local State for Photo Pickers

    @State private var selectedPhotoItems: [PhotosPickerItem] = []

    // MARK: - Initialization

    init(issue: InspectionIssue? = nil, area: InspectionArea? = nil, report: InspectionReport) {
        self.issue = issue
        self.area = area
        self.report = report
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                titleSection
                areaSection
                severitySection
                statusSection
                notesSection
                photosSection
            }
            .navigationTitle(viewModel?.navigationTitle ?? "Issue")
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
            .sheet(isPresented: Binding(
                get: { viewModel?.isShowingCamera ?? false },
                set: { viewModel?.isShowingCamera = $0 }
            )) {
                cameraSheet
            }
            .sheet(isPresented: Binding(
                get: { viewModel?.isShowingPhotoPicker ?? false },
                set: { viewModel?.isShowingPhotoPicker = $0 }
            )) {
                photoPickerSheet
            }
            .sheet(isPresented: Binding(
                get: { viewModel?.showPhotoAnnotation ?? false },
                set: { viewModel?.showPhotoAnnotation = $0 }
            )) {
                annotationSheet
            }
            .alert("Delete Photo?", isPresented: Binding(
                get: { viewModel?.showDeletePhotoConfirmation ?? false },
                set: { viewModel?.showDeletePhotoConfirmation = $0 }
            )) {
                Button("Delete", role: .destructive) {
                    viewModel?.confirmDeletePhoto()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This photo will be permanently deleted. This action cannot be undone.")
            }
            .onAppear {
                viewModel = CreateEditIssueViewModel(
                    issue: issue,
                    area: area,
                    report: report,
                    modelContext: modelContext,
                    onComplete: { }
                )
            }
        }
    }

    // MARK: - Title Section

    private var titleSection: some View {
        Section("Issue Title") {
            TextField("e.g. Cracked tile near sink", text: Binding(
                get: { viewModel?.title ?? "" },
                set: { viewModel?.title = $0 }
            ))
            .font(.body)
            .autocorrectionDisabled()

            if viewModel?.showValidationError ?? false, !(viewModel?.isTitleValid ?? true) {
                Text("Issue title is required")
                    .font(.caption)
                    .foregroundStyle(Theme.error)
            }
        }
    }

    // MARK: - Area Section

    private var areaSection: some View {
        Section("Area") {
            if let areas = viewModel?.availableAreas, !areas.isEmpty {
                Picker("Select Area", selection: Binding(
                    get: { viewModel?.selectedAreaID },
                    set: { viewModel?.selectedAreaID = $0 }
                )) {
                    Text("Choose an area...").tag(UUID?.none)
                    ForEach(areas, id: \.id) { area in
                        Text(area.name).tag(Optional(area.id))
                    }
                }
                .pickerStyle(.menu)
            } else {
                HStack {
                    Text("No areas available")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("Add an area first")
                        .font(.caption)
                        .foregroundStyle(Theme.error)
                }
            }

            if viewModel?.showValidationError ?? false, !(viewModel?.isAreaSelected ?? true) {
                Text("Please select an area")
                    .font(.caption)
                    .foregroundStyle(Theme.error)
            }
        }
    }

    // MARK: - Severity Section

    private var severitySection: some View {
        Section("Severity") {
            HStack(spacing: Theme.spacingS) {
                ForEach(IssueSeverity.allCases, id: \.self) { sev in
                    SeverityOptionButton(
                        severity: sev,
                        isSelected: (viewModel?.severity ?? .medium) == sev
                    ) {
                        viewModel?.severity = sev
                    }
                }
            }
            .padding(.vertical, Theme.spacingXS)
        }
    }

    // MARK: - Status Section

    private var statusSection: some View {
        Section("Status") {
            Picker("Status", selection: Binding(
                get: { viewModel?.status ?? .open },
                set: { viewModel?.status = $0 }
            )) {
                ForEach(IssueStatus.allCases, id: \.self) { status in
                    HStack(spacing: Theme.spacingXS) {
                        Image(systemName: status.icon)
                            .foregroundStyle(status.color)
                        Text(status.displayName)
                    }
                    .tag(status)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    // MARK: - Notes Section

    private var notesSection: some View {
        Section("Notes") {
            TextEditor(text: Binding(
                get: { viewModel?.notes ?? "" },
                set: { viewModel?.notes = $0 }
            ))
            .font(.body)
            .frame(minHeight: 120)
        }
    }

    // MARK: - Photos Section

    private var photosSection: some View {
        Section {
            VStack(alignment: .leading, spacing: Theme.spacingM) {
                // Photo grid
                if let photos = viewModel?.currentPhotos, !photos.isEmpty {
                    photoGrid(photos)
                }

                // Photo action buttons
                HStack(spacing: Theme.spacingM) {
                    Button {
                        viewModel?.isShowingCamera = true
                    } label: {
                        HStack(spacing: Theme.spacingXS) {
                            Image(systemName: "camera.fill")
                            Text("Take Photo")
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Theme.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.spacingS)
                        .background(Theme.primary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMedium, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    Button {
                        viewModel?.isShowingPhotoPicker = true
                    } label: {
                        HStack(spacing: Theme.spacingXS) {
                            Image(systemName: "photo.on.rectangle.angled")
                            Text("Library")
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Theme.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.spacingS)
                        .background(Theme.primary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMedium, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }

                if viewModel?.isProcessingPhotos ?? false {
                    HStack {
                        Spacer()
                        ProgressView("Processing photos...")
                            .font(.caption)
                        Spacer()
                    }
                    .padding(.top, Theme.spacingXS)
                }
            }
        } header: {
            Text("Photos")
        }
    }

    // MARK: - Photo Grid

    private func photoGrid(_ photos: [IssuePhoto]) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80, maximum: 100), spacing: Theme.spacingS)], spacing: Theme.spacingS) {
            ForEach(photos, id: \.id) { photo in
                PhotoGridCell(
                    photo: photo,
                    onTap: { viewModel?.annotatePhoto(photo) },
                    onLongPress: { viewModel?.requestDeletePhoto(photo) }
                )
            }
        }
    }

    // MARK: - Camera Sheet

    @ViewBuilder
    private var cameraSheet: some View {
        if let vm = viewModel {
            CameraCaptureView { image in
                vm.addCapturedPhoto(image: image)
                vm.isShowingCamera = false
            } onCancel: {
                vm.isShowingCamera = false
            }
        }
    }

    // MARK: - Photo Picker Sheet

    @ViewBuilder
    private var photoPickerSheet: some View {
        PhotoPickerView { images in
            viewModel?.isProcessingPhotos = true
            Task { @MainActor in
                for image in images {
                    viewModel?.addCapturedPhoto(image: image)
                }
                viewModel?.isProcessingPhotos = false
                viewModel?.isShowingPhotoPicker = false
            }
        } onCancel: {
            viewModel?.isShowingPhotoPicker = false
        }
    }

    // MARK: - Annotation Sheet

    @ViewBuilder
    private var annotationSheet: some View {
        if let photo = viewModel?.photoToAnnotate {
            PhotoAnnotationView(photo: photo)
        }
    }
}

// MARK: - Severity Option Button

private struct SeverityOptionButton: View {
    let severity: IssueSeverity
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: severity.icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(isSelected ? .white : severity.color)

                Text(severity.displayName)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(isSelected ? .white : .primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.spacingM)
            .background(isSelected ? severity.color : severity.color.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMedium, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radiusMedium, style: .continuous)
                    .stroke(isSelected ? severity.color : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Photo Grid Cell

private struct PhotoGridCell: View {
    let photo: IssuePhoto
    let onTap: () -> Void
    let onLongPress: () -> Void

    var body: some View {
        Button(action: onTap) {
            Group {
                if let uiImage = FileStorageService.shared.loadThumbnail(from: photo.thumbnailImagePath) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    RoundedRectangle(cornerRadius: Theme.radiusSmall, style: .continuous)
                        .fill(Color.gray.opacity(0.2))
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundStyle(.secondary)
                        )
                }
            }
            .frame(height: 90)
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusSmall, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radiusSmall, style: .continuous)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
            )
            .overlay(
                photo.hasAnnotation ? annotationBadge : nil,
                alignment: .topTrailing
            )
            .overlay(
                deleteOverlay,
                alignment: .bottomTrailing
            )
        }
        .buttonStyle(.plain)
        .onLongPressGesture {
            onLongPress()
        }
    }

    private var annotationBadge: some View {
        Image(systemName: "pencil.circle.fill")
            .font(.system(size: 16))
            .foregroundStyle(.white)
            .shadow(radius: 1)
            .padding(4)
    }

    private var deleteOverlay: some View {
        Button(action: onLongPress) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 18))
                .foregroundStyle(Color.red.opacity(0.9))
                .background(Circle().fill(.white))
        }
        .buttonStyle(.plain)
        .padding(4)
    }
}

// MARK: - Preview

#Preview("Create Issue") {
    let container = try! PreviewContainer()
    let report = container.sampleReport
    let area = report.areas!.first!

    return CreateEditIssueView(report: report, area: area)
        .modelContainer(container.container)
}

// MARK: - Preview Helpers

private struct PreviewContainer {
    let container: ModelContainer
    let sampleReport: InspectionReport

    init() throws {
        let schema = Schema([InspectionReport.self, InspectionArea.self, InspectionIssue.self, IssuePhoto.self])
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

        let kitchen = InspectionArea(name: "Kitchen", notes: "Main kitchen")
        context.insert(kitchen)
        kitchen.report = sampleReport
        sampleReport.areas = [kitchen]

        try context.save()
    }
}
