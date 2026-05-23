// SnagSnap
// PhotoPickerView.swift
//
// Photo library picker using PhotosUI framework with multi-selection support.

import SwiftUI
import PhotosUI

// MARK: - PhotoPickerView

/// A sheet view that presents the system PhotosPicker for multi-selection,
/// handles loading and processing of selected images.
struct PhotoPickerView: View {

    // MARK: - Callbacks

    let onPhotosSelected: ([UIImage]) -> Void
    let onCancel: () -> Void

    // MARK: - State

    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var isProcessing: Bool = false
    @State private var processingProgress: Double = 0.0
    @State private var loadedImages: [UIImage] = []

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if isProcessing {
                    processingView
                } else {
                    PhotosPicker(
                        selection: $selectedItems,
                        maxSelectionCount: 10,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        VStack(spacing: Theme.spacingL) {
                            Spacer()

                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 64, weight: .light))
                                .foregroundStyle(Theme.primary.opacity(0.5))

                            Text("Select Photos")
                                .font(.title2.weight(.semibold))

                            Text("Tap to browse your photo library and select up to 10 images to attach to this issue.")
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, Theme.spacingXL)

                            SSButton(
                                "Open Photo Library",
                                style: .primary,
                                icon: "photo",
                                isFullWidth: false
                            ) {
                                // Trigger is handled by the wrapper
                            }
                            .padding(.top, Theme.spacingM)

                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .contentShape(Rectangle())
                    }
                }
            }
            .navigationTitle("Choose Photos")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if !isProcessing {
                            onCancel()
                        }
                    }
                    .foregroundStyle(isProcessing ? .secondary : Theme.primary)
                    .disabled(isProcessing)
                }
            }
            .onChange(of: selectedItems) { _, newItems in
                guard !newItems.isEmpty else { return }
                processSelectedItems(newItems)
            }
        }
    }

    // MARK: - Processing View

    private var processingView: some View {
        VStack(spacing: Theme.spacingL) {
            Spacer()

            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 6)
                    .frame(width: 120, height: 120)

                Circle()
                    .trim(from: 0, to: processingProgress)
                    .stroke(Theme.primary, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.3), value: processingProgress)

                VStack {
                    Text("\(Int(processingProgress * 100))%")
                        .font(.title3.weight(.semibold))
                        .monospacedDigit()
                }
            }

            Text("Processing photos...")
                .font(.headline)

            Text("Loading and preparing your selected images.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.spacingXL)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Process Selected Items

    private func processSelectedItems(_ items: [PhotosPickerItem]) {
        isProcessing = true
        processingProgress = 0.0
        loadedImages.removeAll()

        Task { @MainActor in
            let totalCount = items.count
            var images: [UIImage] = []

            for (index, item) in items.enumerated() {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    images.append(uiImage)
                }

                processingProgress = Double(index + 1) / Double(totalCount)
                // Small delay to allow UI to update
                try? await Task.sleep(nanoseconds: 50_000_000)
            }

            loadedImages = images
            isProcessing = false
            selectedItems.removeAll()
            onPhotosSelected(images)
        }
    }
}

// MARK: - Alternative Direct PhotosPicker View

/// A view that directly embeds the PhotosPicker using the selection binding.
/// This is useful for inline usage within other views.
struct PhotoLibraryPicker: View {
    @Binding var selectedItems: [PhotosPickerItem]
    let maxSelection: Int
    let matching: PHPickerFilter

    var body: some View {
        PhotosPicker(
            selection: $selectedItems,
            maxSelectionCount: maxSelection,
            matching: matching,
            photoLibrary: .shared()
        ) {
            HStack(spacing: Theme.spacingXS) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.body)
                Text("Choose from Library")
                    .font(.subheadline.weight(.medium))
            }
            .foregroundStyle(Theme.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.spacingM)
            .background(Theme.primary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMedium, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("Photo Picker") {
    PhotoPickerView { images in
        print("Selected \(images.count) images")
    } onCancel: {
        print("Cancelled")
    }
}
