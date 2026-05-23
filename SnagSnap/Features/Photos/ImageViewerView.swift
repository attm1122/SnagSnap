// SnagSnap
// ImageViewerView.swift
//
// Full-screen image viewer with original/annotated tabs and sharing.

import SwiftUI

/// Displays an issue photo in full screen with support for viewing
/// both the original and annotated versions, plus sharing.
struct ImageViewerView: View {
    
    @Environment(\.dismiss) private var dismiss
    @State private var showAnnotated = false
    @State private var showShareSheet = false
    @State private var currentImage: UIImage?
    
    let photo: IssuePhoto
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if let image = currentImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit
                        .ignoresSafeArea()
                } else {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        // Toggle original / annotated
                        if photo.hasAnnotation {
                            Button {
                                HapticService.shared.play(.light)
                                showAnnotated.toggle()
                                loadCurrentImage()
                            } label: {
                                Text(showAnnotated ? "Original" : "Annotated")
                                    .font(.subheadline.weight(.medium))
                            }
                            .foregroundStyle(.white)
                        }
                        
                        // Share
                        if currentImage != nil {
                            Button {
                                HapticService.shared.play(.medium)
                                showShareSheet = true
                            } label: {
                                Image(systemName: "square.and.arrow.up")
                            }
                            .foregroundStyle(.white)
                        }
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let image = currentImage {
                    ShareSheet(activityItems: [image])
                }
            }
            .onAppear {
                loadCurrentImage()
            }
        }
    }
    
    private func loadCurrentImage() {
        if showAnnotated, let annotatedPath = photo.annotatedImagePath {
            currentImage = FileStorageService.shared.loadAnnotatedImage(from: annotatedPath)
        } else {
            currentImage = FileStorageService.shared.loadImage(from: photo.originalImagePath)
        }
    }
}

// MARK: - Share Sheet (UIViewControllerRepresentable)

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let vc = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        vc.excludedActivityTypes = [.assignToContact, .postToFacebook, .postToTwitter]
        return vc
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
