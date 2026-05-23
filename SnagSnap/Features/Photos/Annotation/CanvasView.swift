// SnagSnap
// CanvasView.swift
//
// UIViewRepresentable wrapper for PKCanvasView with tool picker, undo support,
// and background image setup for photo annotation.

import SwiftUI
import PencilKit
import UIKit

// MARK: - CanvasView

/// A SwiftUI wrapper around PKCanvasView that provides a full annotation canvas
/// overlaid on a background image. Integrates with PKToolPicker for drawing tools,
/// supports undo/redo, and reports drawing state changes.
struct CanvasView: UIViewRepresentable {

    // MARK: - Configuration

    /// The background image to display behind the canvas (the photo being annotated).
    let backgroundImage: UIImage

    /// The currently selected PKInkingTool (managed by parent).
    @Binding var selectedTool: PKInkingTool

    /// Whether the canvas has any drawing strokes.
    @Binding var isEmpty: Bool

    /// Binding to trigger an undo action from external controls.
    @Binding var undoTrigger: Bool

    /// Binding to trigger a clear-all action from external controls.
    @Binding var clearTrigger: Bool

    /// Binding to trigger a save (export drawing) action from external controls.
    @Binding var saveTrigger: Bool

    /// Callback invoked when the user requests to save the annotated image.
    let onSave: (UIImage) -> Void

    // MARK: - Coordinator

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    // MARK: - UIViewRepresentable

    func makeUIView(context: Context) -> CanvasUIView {
        let canvasView = CanvasUIView()
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false

        // Set up the background image
        let imageView = UIImageView(image: backgroundImage)
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.isUserInteractionEnabled = false
        imageView.tag = 100 // Tag for later reference
        canvasView.addSubview(imageView)
        canvasView.sendSubviewToBack(imageView)

        // Configure PKCanvasView
        canvasView.drawingPolicy = .anyInput // Support finger, Pencil, and stylus
        canvasView.delegate = context.coordinator

        // Set up the drawing to use the full image bounds
        let drawingSize = backgroundImage.size
        canvasView.contentSize = drawingSize
        canvasView.minimumZoomScale = 1.0
        canvasView.maximumZoomScale = 3.0
        canvasView.zoomScale = 1.0

        // Make canvas non-scrollable (we handle zoom ourselves if needed)
        canvasView.isScrollEnabled = false

        // Set the background image view to match canvas bounds
        imageView.frame = CGRect(origin: .zero, size: drawingSize)

        // Store coordinator reference for callbacks
        context.coordinator.canvasView = canvasView

        // Set up tool picker
        let toolPicker = PKToolPicker()
        toolPicker.setVisible(true, forFirstResponder: canvasView)
        toolPicker.addObserver(context.coordinator)
        context.coordinator.toolPicker = toolPicker

        canvasView.becomeFirstResponder()

        // Bind the selected tool
        canvasView.tool = selectedTool

        return canvasView
    }

    func updateUIView(_ canvasView: CanvasUIView, context: Context) {
        canvasView.tool = selectedTool

        // Handle undo trigger
        if undoTrigger {
            context.coordinator.performUndo()
            DispatchQueue.main.async {
                undoTrigger = false
            }
        }

        // Handle clear trigger
        if clearTrigger {
            context.coordinator.performClear()
            DispatchQueue.main.async {
                clearTrigger = false
            }
        }

        // Handle save trigger
        if saveTrigger {
            context.coordinator.performSave()
            DispatchQueue.main.async {
                saveTrigger = false
            }
        }
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, PKCanvasViewDelegate, PKToolPickerObserver {
        let parent: CanvasView
        weak var canvasView: CanvasUIView?
        weak var toolPicker: PKToolPicker?

        init(parent: CanvasView) {
            self.parent = parent
        }

        // MARK: - PKCanvasViewDelegate

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            DispatchQueue.main.async { [weak self] in
                self?.parent.isEmpty = canvasView.drawing.bounds.isEmpty
            }
        }

        func toolPickerSelectedToolDidChange(_ toolPicker: PKToolPicker) {
            // Tool changes are driven by the SwiftUI controls.
        }

        func toolPickerIsRulerActiveDidChange(_ toolPicker: PKToolPicker) {
            // Ruler state changes do not affect the saved annotation.
        }

        // MARK: - Actions

        func performUndo() {
            guard let canvasView = canvasView else { return }
            // PKCanvasView uses the undo manager for stroke-level undo
            if let undoManager = canvasView.undoManager, undoManager.canUndo {
                undoManager.undo()
            }
        }

        func performClear() {
            guard let canvasView = canvasView else { return }
            canvasView.drawing = PKDrawing()
            parent.isEmpty = true
        }

        func performSave() {
            guard let canvasView = canvasView, let imageView = canvasView.viewWithTag(100) as? UIImageView else { return }

            // Render the background image + annotations into a single image
            let renderer = UIGraphicsImageRenderer(size: imageView.bounds.size)
            let combinedImage = renderer.image { context in
                // Draw the background image
                imageView.layer.render(in: context.cgContext)

                // Draw the annotations on top
                let drawingImage = canvasView.drawing.image(from: imageView.bounds, scale: UIScreen.main.scale)
                drawingImage.draw(in: imageView.bounds)
            }

            parent.onSave(combinedImage)
        }
    }
}

// MARK: - CanvasUIView

/// A custom PKCanvasView subclass that provides additional functionality
/// for the annotation use case.
final class CanvasUIView: PKCanvasView {

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        // Configure for finger + Apple Pencil input
        drawingPolicy = .anyInput
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()

        // Keep the background image view sized to match the canvas content
        if let imageView = viewWithTag(100) {
            imageView.frame = bounds
        }
    }
}
