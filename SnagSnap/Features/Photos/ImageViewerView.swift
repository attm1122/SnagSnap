// SnagSnap
// ImageViewerView.swift
//
// Full-screen image viewer with original/annotated toggle and sharing.

import SwiftUI

// MARK: - ImageViewerView

/// Full-screen image viewer that displays an issue photo with support for
/// toggling between original and annotated versions, zoom/pan, and sharing.
struct ImageViewerView: View {

    // MARK: - Properties

    let photo: IssuePhoto
    var initialShowAnnotated: Bool = false

    // MARK: - Local State

    @Environment(\.dismiss) private var dismiss
    @State private var showAnnotated: Bool = false
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    // MARK: - Computed Properties

    private var displayImage: UIImage? {
        if showAnnotated, let annotatedPath = photo.annotatedImagePath {
            return FileStorageService.shared.loadAnnotatedImage(from: annotatedPath)
                ?? FileStorageService.shared.loadImage(from: photo.originalImagePath)
        }
        return FileStorageService.shared.loadImage(from: photo.originalImagePath)
    }

    private var hasAnnotatedVersion: Bool {
        photo.annotatedImagePath != nil
    }

    private var navigationTitle: String {
        if let caption = photo.caption, !caption.isEmpty {
            return caption
        }
        return showAnnotated && hasAnnotatedVersion ? "Annotated" : "Original"
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if let uiImage = displayImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(magnificationGesture)
                        .gesture(dragGesture)
                        .onTapGesture(count: 2) {
                            withAnimation(.spring()) {
                                scale = 1.0
                                offset = .zero
                                lastScale = 1.0
                                lastOffset = .zero
                            }
                        }
                } else {
                    VStack(spacing: Theme.spacingM) {
                        Image(systemName: "photo")
                            .font(.system(size: 64))
                            .foregroundStyle(.secondary)
                        Text("Unable to load image")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: Theme.spacingS) {
                        // Toggle original/annotated
                        if hasAnnotatedVersion {
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showAnnotated.toggle()
                                }
                                HapticService.shared.play(.light)
                            } label: {
                                Image(systemName: showAnnotated ? "pencil.circle.fill" : "pencil.circle")
                                    .font(.system(size: 18))
                            }
                            .foregroundStyle(.white)
                            .accessibilityLabel(showAnnotated ? "Show original" : "Show annotated")
                        }

                        // Share button
                        Button {
                            shareCurrentImage()
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 18))
                        }
                        .foregroundStyle(.white)
                        .accessibilityLabel("Share image")
                    }
                }
            }
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .onAppear {
            showAnnotated = initialShowAnnotated && hasAnnotatedVersion
        }
    }

    // MARK: - Gestures

    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let delta = value / lastScale
                lastScale = value
                scale = min(max(scale * delta, 1.0), 5.0)
            }
            .onEnded { _ in
                lastScale = 1.0
                if scale < 1.0 {
                    withAnimation(.spring()) {
                        scale = 1.0
                        offset = .zero
                        lastOffset = .zero
                    }
                }
            }
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                guard scale > 1.0 else { return }
                offset = CGSize(
                    width: lastOffset.width + value.translation.width,
                    height: lastOffset.height + value.translation.height
                )
            }
            .onEnded { _ in
                lastOffset = offset
            }
    }

    // MARK: - Share

    private func shareCurrentImage() {
        guard let image = displayImage else { return }
        let caption = photo.caption
        ShareService.shared.shareImage(image, caption: caption)
    }
}
