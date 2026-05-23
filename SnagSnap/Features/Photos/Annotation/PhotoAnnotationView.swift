// SnagSnap
// PhotoAnnotationView.swift
//
// Full-screen photo annotation view using PencilKit for drawing on photos.

import SwiftUI
import PencilKit
import UIKit

// MARK: - PhotoAnnotationViewModel

/// View model managing the state and logic for photo annotation.
@Observable
final class PhotoAnnotationViewModel {

    // MARK: - State

    var selectedTool: PKInkingTool
    var isCanvasEmpty: Bool = true
    var undoTrigger: Bool = false
    var clearTrigger: Bool = false
    var saveTrigger: Bool = false
    var isSaving: Bool = false
    var showClearConfirmation: Bool = false
    var showExitConfirmation: Bool = false
    var hasUnsavedChanges: Bool = false
    var errorMessage: String?
    var showError: Bool = false

    // MARK: - Dependencies

    let photo: IssuePhoto
    private let modelContext: ModelContext?
    private let onComplete: () -> Void

    // MARK: - Computed Properties

    var backgroundImage: UIImage? {
        // Prefer annotated version if it exists, otherwise use original
        if let annotatedPath = photo.annotatedImagePath,
           let annotatedImage = FileStorageService.shared.loadImage(from: annotatedPath) {
            return annotatedImage
        }
        return FileStorageService.shared.loadImage(from: photo.originalImagePath)
    }

    // MARK: - Initialization

    init(
        photo: IssuePhoto,
        modelContext: ModelContext? = nil,
        onComplete: @escaping () -> Void = {}
    ) {
        self.photo = photo
        self.modelContext = modelContext
        self.onComplete = onComplete
        // Default tool: black pen with 3pt width
        self.selectedTool = PKInkingTool(.pen, color: .red, width: 3)
    }

    // MARK: - Actions

    func undo() {
        undoTrigger = true
    }

    func clearAll() {
        if !isCanvasEmpty {
            showClearConfirmation = true
        }
    }

    func confirmClear() {
        clearTrigger = true
        hasUnsavedChanges = true
    }

    func saveAnnotation() {
        saveTrigger = true
    }

    /// Handles the annotated image after it's been rendered from the canvas.
    func handleAnnotatedImage(_ image: UIImage) {
        isSaving = true
        defer { isSaving = false }

        do {
            // Save the annotated image
            let annotatedPath = try FileStorageService.shared.saveAnnotatedImage(image, for: photo.id)

            // Update the photo model
            photo.annotatedImagePath = annotatedPath
            photo.updatedAt = Date()

            if let context = modelContext {
                try context.save()
            }

            hasUnsavedChanges = false
            onComplete()
        } catch {
            errorMessage = "Failed to save annotation: \(error.localizedDescription)"
            showError = true
        }
    }

    func cancel() {
        if hasUnsavedChanges && !isCanvasEmpty {
            showExitConfirmation = true
        } else {
            onComplete()
        }
    }

    func discardAndExit() {
        hasUnsavedChanges = false
        onComplete()
    }

    func drawingDidChange(isEmpty: Bool) {
        if !isEmpty {
            hasUnsavedChanges = true
        }
        self.isCanvasEmpty = isEmpty
    }
}

// MARK: - PhotoAnnotationView

/// Full-screen photo annotation view that overlays a PencilKit canvas on a photo,
/// providing tools for drawing, marking up, and saving annotated images.
struct PhotoAnnotationView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // MARK: - Properties

    let photo: IssuePhoto

    // MARK: - View Model

    @State private var viewModel: PhotoAnnotationViewModel?

    // MARK: - Local State

    @State private var showToolPicker: Bool = true
    @State private var showColorPicker: Bool = false
    @State private var selectedInkType: PKInkingTool.InkType = .pen
    @State private var selectedColor: Color = .red
    @State private var selectedWidth: CGFloat = 3.0

    // MARK: - Initialization

    init(photo: IssuePhoto) {
        self.photo = photo
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                if let vm = viewModel, let backgroundImage = vm.backgroundImage {
                    annotationCanvasView(image: backgroundImage, viewModel: vm)
                } else {
                    errorView
                }

                if viewModel?.isSaving ?? false {
                    savingOverlay
                }
            }
            .navigationTitle("Annotate Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        viewModel?.cancel()
                        dismiss()
                    }
                    .foregroundStyle(.primary)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: Theme.spacingS) {
                        Button {
                            viewModel?.saveAnnotation()
                        } label: {
                            Text("Done")
                                .font(.body.weight(.semibold))
                        }
                        .disabled(viewModel?.isCanvasEmpty ?? true)
                        .foregroundStyle((viewModel?.isCanvasEmpty ?? true) ? .secondary : Theme.success)
                    }
                }
            }
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .alert("Clear All Annotations?", isPresented: Binding(
                get: { viewModel?.showClearConfirmation ?? false },
                set: { viewModel?.showClearConfirmation = $0 }
            )) {
                Button("Clear All", role: .destructive) {
                    viewModel?.confirmClear()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will erase all your annotations. This action cannot be undone.")
            }
            .alert("Unsaved Changes", isPresented: Binding(
                get: { viewModel?.showExitConfirmation ?? false },
                set: { viewModel?.showExitConfirmation = $0 }
            )) {
                Button("Discard Changes", role: .destructive) {
                    viewModel?.discardAndExit()
                    dismiss()
                }
                Button("Keep Editing", role: .cancel) {}
            } message: {
                Text("You have unsaved annotations. Are you sure you want to leave without saving?")
            }
            .alert("Error", isPresented: Binding(
                get: { viewModel?.showError ?? false },
                set: { viewModel?.showError = $0 }
            )) {
                Button("OK") {}
            } message: {
                Text(viewModel?.errorMessage ?? "An unknown error occurred.")
            }
            .onAppear {
                viewModel = PhotoAnnotationViewModel(
                    photo: photo,
                    modelContext: modelContext,
                    onComplete: { dismiss() }
                )
            }
        }
    }

    // MARK: - Annotation Canvas View

    private func annotationCanvasView(image: UIImage, viewModel: PhotoAnnotationViewModel) -> some View {
        VStack(spacing: 0) {
            // Main canvas area
            GeometryReader { geometry in
                let aspectRatio = image.size.width / image.size.height
                let containerSize = geometry.size

                let displaySize: CGSize
                let containerAspect = containerSize.width / containerSize.height

                if aspectRatio > containerAspect {
                    // Image is wider than container
                    displaySize = CGSize(
                        width: containerSize.width,
                        height: containerSize.width / aspectRatio
                    )
                } else {
                    // Image is taller than container
                    displaySize = CGSize(
                        width: containerSize.height * aspectRatio,
                        height: containerSize.height
                    )
                }

                ZStack {
                    // Background
                    Color.black.ignoresSafeArea()

                    // Image + Canvas
                    ZStack {
                        // Background image
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit
                            .frame(width: displaySize.width, height: displaySize.height)

                        // PencilKit Canvas overlay
                        CanvasView(
                            backgroundImage: image,
                            selectedTool: Binding(
                                get: { viewModel.selectedTool },
                                set: { viewModel.selectedTool = $0 }
                            ),
                            isEmpty: Binding(
                                get: { viewModel.isCanvasEmpty },
                                set: { viewModel.isCanvasEmpty = $0 }
                            ),
                            undoTrigger: $viewModel.undoTrigger,
                            clearTrigger: $viewModel.clearTrigger,
                            saveTrigger: $viewModel.saveTrigger,
                            onSave: { annotatedImage in
                                viewModel.handleAnnotatedImage(annotatedImage)
                            }
                        )
                        .frame(width: displaySize.width, height: displaySize.height)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            // Bottom toolbar
            bottomToolbar(viewModel: viewModel)
        }
    }

    // MARK: - Bottom Toolbar

    private func bottomToolbar(viewModel: PhotoAnnotationViewModel) -> some View {
        HStack(spacing: Theme.spacingXL) {
            // Undo button
            Button {
                viewModel.undo()
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 22, weight: .medium))
                    Text("Undo")
                        .font(.caption2)
                }
                .foregroundStyle(.primary)
            }
            .disabled(viewModel.isCanvasEmpty)
            .opacity(viewModel.isCanvasEmpty ? 0.4 : 1.0)

            // Tool type picker
            toolTypeMenu(viewModel: viewModel)

            // Color picker
            colorPickerMenu(viewModel: viewModel)

            // Width slider
            widthControl(viewModel: viewModel)

            // Clear all button
            Button {
                viewModel.clearAll()
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "eraser.fill")
                        .font(.system(size: 22, weight: .medium))
                    Text("Clear")
                        .font(.caption2)
                }
                .foregroundStyle(viewModel.isCanvasEmpty ? .secondary : Theme.error)
            }
            .disabled(viewModel.isCanvasEmpty)
        }
        .padding(.vertical, Theme.spacingM)
        .padding(.horizontal, Theme.spacingL)
        .background(.ultraThinMaterial)
    }

    // MARK: - Tool Type Menu

    private func toolTypeMenu(viewModel: PhotoAnnotationViewModel) -> some View {
        Menu {
            Button {
                updateTool(viewModel: viewModel, inkType: .pen)
            } label: {
                HStack {
                    Image(systemName: "pencil")
                    Text("Pen")
                }
            }

            Button {
                updateTool(viewModel: viewModel, inkType: .marker)
            } label: {
                HStack {
                    Image(systemName: "highlighter")
                    Text("Marker")
                }
            }

            Button {
                updateTool(viewModel: viewModel, inkType: .pencil)
            } label: {
                HStack {
                    Image(systemName: "pencil.line")
                    Text("Pencil")
                }
            }

            Button {
                updateTool(viewModel: viewModel, inkType: .eraser)
            } label: {
                HStack {
                    Image(systemName: "eraser")
                    Text("Eraser")
                }
            }

            Button {
                updateTool(viewModel: viewModel, inkType: .lasso)
            } label: {
                HStack {
                    Image(systemName: "lasso")
                    Text("Lasso Select")
                }
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: toolIcon(for: selectedInkType))
                    .font(.system(size: 22, weight: .medium))
                Text("Tool")
                    .font(.caption2)
            }
            .foregroundStyle(Theme.primary)
        }
    }

    private func toolIcon(for inkType: PKInkingTool.InkType) -> String {
        switch inkType {
        case .pen: return "pencil"
        case .marker: return "highlighter"
        case .pencil: return "pencil.line"
        case .eraser: return "eraser"
        case .lasso: return "lasso"
        @unknown default: return "pencil"
        }
    }

    private func updateTool(viewModel: PhotoAnnotationViewModel, inkType: PKInkingTool.InkType) {
        selectedInkType = inkType
        let color = inkType == .eraser ? UIColor.clear : UIColor(selectedColor)
        viewModel.selectedTool = PKInkingTool(inkType, color: color, width: selectedWidth)
    }

    // MARK: - Color Picker Menu

    private func colorPickerMenu(viewModel: PhotoAnnotationViewModel) -> some View {
        Menu {
            let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .white, .black]

            ForEach(colors, id: \.self) { color in
                Button {
                    selectedColor = color
                    updateTool(viewModel: viewModel, inkType: selectedInkType)
                } label: {
                    HStack {
                        Circle()
                            .fill(color)
                            .frame(width: 20, height: 20)
                            .overlay(
                                Circle()
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                            )
                        Text(colorName(color))
                        if selectedColor == color {
                            Image(systemName: "checkmark")
                                .font(.caption.weight(.semibold))
                        }
                    }
                }
            }
        } label: {
            VStack(spacing: 4) {
                Circle()
                    .fill(selectedColor)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                    )
                Text("Color")
                    .font(.caption2)
            }
        }
    }

    private func colorName(_ color: Color) -> String {
        switch color {
        case .red: return "Red"
        case .orange: return "Orange"
        case .yellow: return "Yellow"
        case .green: return "Green"
        case .blue: return "Blue"
        case .purple: return "Purple"
        case .white: return "White"
        case .black: return "Black"
        default: return "Custom"
        }
    }

    // MARK: - Width Control

    private func widthControl(viewModel: PhotoAnnotationViewModel) -> some View {
        Menu {
            Button {
                selectedWidth = 1.0
                updateTool(viewModel: viewModel, inkType: selectedInkType)
            } label: {
                HStack {
                    Text("Thin")
                    Spacer()
                    if abs(selectedWidth - 1.0) < 0.1 {
                        Image(systemName: "checkmark")
                    }
                }
            }

            Button {
                selectedWidth = 3.0
                updateTool(viewModel: viewModel, inkType: selectedInkType)
            } label: {
                HStack {
                    Text("Medium")
                    Spacer()
                    if abs(selectedWidth - 3.0) < 0.1 {
                        Image(systemName: "checkmark")
                    }
                }
            }

            Button {
                selectedWidth = 6.0
                updateTool(viewModel: viewModel, inkType: selectedInkType)
            } label: {
                HStack {
                    Text("Thick")
                    Spacer()
                    if abs(selectedWidth - 6.0) < 0.1 {
                        Image(systemName: "checkmark")
                    }
                }
            }

            Button {
                selectedWidth = 12.0
                updateTool(viewModel: viewModel, inkType: selectedInkType)
            } label: {
                HStack {
                    Text("Extra Thick")
                    Spacer()
                    if abs(selectedWidth - 12.0) < 0.1 {
                        Image(systemName: "checkmark")
                    }
                }
            }
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .stroke(Theme.primary, lineWidth: 1.5)
                        .frame(width: 24, height: 24)
                    Circle()
                        .fill(Theme.primary)
                        .frame(width: max(4, selectedWidth * 2), height: max(4, selectedWidth * 2))
                }
                Text("Size")
                    .font(.caption2)
            }
            .foregroundStyle(.primary)
        }
    }

    // MARK: - Error View

    private var errorView: some View {
        VStack(spacing: Theme.spacingL) {
            Spacer()

            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 56))
                .foregroundStyle(Theme.warning)

            Text("Could Not Load Photo")
                .font(.title2.weight(.semibold))

            Text("The photo could not be loaded for annotation. It may have been deleted or moved.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.spacingXL)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Saving Overlay

    private var savingOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            VStack(spacing: Theme.spacingM) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)

                Text("Saving annotation...")
                    .font(.headline)
                    .foregroundStyle(.white)
            }
            .padding(Theme.spacingXL)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusLarge, style: .continuous))
        }
    }
}

// MARK: - Preview

#Preview("Photo Annotation") {
    let container = try! PreviewContainer()
    let photo = container.photo

    return PhotoAnnotationView(photo: photo)
        .modelContainer(container.container)
}

// MARK: - Preview Helpers

private struct PreviewContainer {
    let container: ModelContainer
    let photo: IssuePhoto

    init() throws {
        let schema = Schema([InspectionReport.self, InspectionArea.self, InspectionIssue.self, IssuePhoto.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])

        let context = ModelContext(container)

        // Create a simple colored image for preview
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 400, height: 300))
        let image = renderer.image { ctx in
            UIColor.systemBlue.setFill()
            ctx.fill(CGRect(origin: .zero, size: CGSize(width: 400, height: 300)))

            // Draw a simple room shape
            UIColor.white.setFill()
            ctx.fill(CGRect(x: 50, y: 50, width: 300, height: 200))

            UIColor.label.setStroke()
            let path = UIBezierPath(rect: CGRect(x: 50, y: 50, width: 300, height: 200))
            path.lineWidth = 2
            path.stroke()
        }

        let paths = try FileStorageService.shared.saveImage(image)

        photo = IssuePhoto(
            originalImagePath: paths.originalPath,
            thumbnailImagePath: paths.thumbnailPath,
            caption: "Kitchen overview"
        )
        context.insert(photo)

        try context.save()
    }
}
