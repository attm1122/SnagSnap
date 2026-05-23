//
//  FileStorageService.swift
//  SnagSnap
//
//  Service for managing image, thumbnail, and PDF file storage on device.
//

import Foundation
import UIKit

/// Errors that can occur during file storage operations.
enum FileStorageError: Error, LocalizedError {
    case invalidImageData
    case thumbnailGenerationFailed
    case fileNotFound
    case saveFailed
    case deleteFailed
    case directoryCreationFailed
    case pdfGenerationFailed
    case invalidFilePath

    var errorDescription: String? {
        switch self {
        case .invalidImageData:
            return "Could not process image data. The image may be corrupted or in an unsupported format."
        case .thumbnailGenerationFailed:
            return "Failed to generate thumbnail from the provided image."
        case .fileNotFound:
            return "The requested file was not found in storage."
        case .saveFailed:
            return "Failed to save the file to device storage."
        case .deleteFailed:
            return "Failed to delete the file from device storage."
        case .directoryCreationFailed:
            return "Failed to create the storage directory structure."
        case .pdfGenerationFailed:
            return "Failed to generate PDF data."
        case .invalidFilePath:
            return "The provided file path is invalid."
        }
    }
}

/// Centralized service for all file I/O operations including images, thumbnails, and PDFs.
///
/// `FileStorageService` manages three separate directories within the app's Documents folder:
/// - **Images/**: Stores full-resolution JPEG images captured during inspections.
/// - **Thumbnails/**: Stores downscaled JPEG thumbnails for fast UI rendering.
/// - **PDFs/**: Stores generated inspection report PDFs.
///
/// All public methods are thread-safe and can be called from any queue.
@Observable
class FileStorageService {

    // MARK: - Shared Instance

    /// The shared singleton instance of `FileStorageService`.
    static let shared = FileStorageService()

    // MARK: - Properties

    /// The underlying file manager used for all file operations.
    private let fileManager: FileManager

    /// Directory URL for storing full-resolution images.
    private let imagesDirectory: URL

    /// Directory URL for storing generated PDF documents.
    private let pdfsDirectory: URL

    /// Directory URL for storing thumbnail images.
    private let thumbnailsDirectory: URL

    // MARK: - Initialization

    /// Creates a new `FileStorageService` instance.
    ///
    /// - Parameter fileManager: The `FileManager` to use for file operations.
    ///   Defaults to `.default`. Can be injected for testing.
    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        let docsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.imagesDirectory = docsDir.appendingPathComponent("Images", isDirectory: true)
        self.thumbnailsDirectory = docsDir.appendingPathComponent("Thumbnails", isDirectory: true)
        self.pdfsDirectory = docsDir.appendingPathComponent("PDFs", isDirectory: true)
        try? ensureDirectoriesExist()
    }

    // MARK: - Public Methods - Image Storage

    /// Saves a `UIImage` to disk and generates a corresponding thumbnail.
    ///
    /// - Parameter image: The `UIImage` to save. Must be convertible to JPEG data.
    /// - Returns: A tuple containing the filename (not full path) of the saved original image
    ///   and the saved thumbnail.
    /// - Throws: `FileStorageError.invalidImageData` if the image cannot be converted to JPEG.
    ///           `FileStorageError.saveFailed` if writing to disk fails.
    ///           `FileStorageError.thumbnailGenerationFailed` if thumbnail creation fails.
    func saveImage(_ image: UIImage) throws -> (originalPath: String, thumbnailPath: String) {
        let filename = uniqueFilename() + ".jpg"
        let originalURL = imagesDirectory.appendingPathComponent(filename)
        let thumbnailURL = thumbnailsDirectory.appendingPathComponent(filename)

        guard let imageData = image.jpegData(compressionQuality: 0.85) else {
            throw FileStorageError.invalidImageData
        }

        do {
            try imageData.write(to: originalURL, options: .atomic)
        } catch {
            throw FileStorageError.saveFailed
        }

        let thumbnail = generateThumbnail(from: image, size: CGSize(width: 200, height: 200))
        guard let thumbnailData = thumbnail.jpegData(compressionQuality: 0.7) else {
            // Clean up the original if thumbnail fails
            try? fileManager.removeItem(at: originalURL)
            throw FileStorageError.thumbnailGenerationFailed
        }

        do {
            try thumbnailData.write(to: thumbnailURL, options: .atomic)
        } catch {
            // Clean up the original if thumbnail save fails
            try? fileManager.removeItem(at: originalURL)
            throw FileStorageError.saveFailed
        }

        return (originalPath: filename, thumbnailPath: filename)
    }

    /// Saves an annotated version of an image, typically after markup with PencilKit.
    ///
    /// - Parameters:
    ///   - image: The annotated `UIImage` to save.
    ///   - photoID: The unique identifier of the photo being annotated.
    /// - Returns: The filename of the saved annotated image.
    /// - Throws: `FileStorageError.invalidImageData` if the image cannot be converted to JPEG.
    ///           `FileStorageError.saveFailed` if writing to disk fails.
    func saveAnnotatedImage(_ image: UIImage, for photoID: UUID) throws -> String {
        let filename = "annotated_\(photoID.uuidString).jpg"
        let url = imagesDirectory.appendingPathComponent(filename)

        guard let data = image.jpegData(compressionQuality: 0.9) else {
            throw FileStorageError.invalidImageData
        }

        do {
            try data.write(to: url, options: .atomic)
        } catch {
            throw FileStorageError.saveFailed
        }

        return filename
    }

    /// Loads a full-resolution image from a stored filename.
    ///
    /// - Parameter path: The filename (not full path) of the stored image.
    /// - Returns: The loaded `UIImage`, or `nil` if the file doesn't exist or is unreadable.
    func loadImage(from path: String) -> UIImage? {
        guard !path.isEmpty else { return nil }
        let url = imagesDirectory.appendingPathComponent(path)
        guard fileManager.fileExists(atPath: url.path) else { return nil }
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    /// Loads a thumbnail image from a stored filename.
    ///
    /// - Parameter path: The filename (not full path) of the stored thumbnail.
    /// - Returns: The loaded thumbnail `UIImage`, or `nil` if the file doesn't exist or is unreadable.
    func loadThumbnail(from path: String) -> UIImage? {
        guard !path.isEmpty else { return nil }
        let url = thumbnailsDirectory.appendingPathComponent(path)
        guard fileManager.fileExists(atPath: url.path) else { return nil }
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    /// Loads an annotated image from a stored filename.
    ///
    /// - Parameter path: The filename (not full path) of the stored annotated image.
    /// - Returns: The loaded annotated `UIImage`, or `nil` if the file doesn't exist or is unreadable.
    func loadAnnotatedImage(from path: String) -> UIImage? {
        guard !path.isEmpty else { return nil }
        let url = imagesDirectory.appendingPathComponent(path)
        guard fileManager.fileExists(atPath: url.path) else { return nil }
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    /// Deletes an image and its associated thumbnail from storage.
    ///
    /// Also attempts to delete any annotated version of the image.
    /// Nonexistent files are silently ignored.
    ///
    /// - Parameter path: The filename (not full path) of the image to delete.
    /// - Throws: `FileStorageError.deleteFailed` if deletion fails for an existing file.
    func deleteImage(at path: String) throws {
        let imageURL = imagesDirectory.appendingPathComponent(path)
        if fileManager.fileExists(atPath: imageURL.path) {
            do {
                try fileManager.removeItem(at: imageURL)
            } catch {
                throw FileStorageError.deleteFailed
            }
        }

        let thumbnailURL = thumbnailsDirectory.appendingPathComponent(path)
        if fileManager.fileExists(atPath: thumbnailURL.path) {
            try? fileManager.removeItem(at: thumbnailURL)
        }

        // Also attempt to delete any annotated version
        let annotatedURL = imagesDirectory.appendingPathComponent("annotated_" + path)
        if fileManager.fileExists(atPath: annotatedURL.path) {
            try? fileManager.removeItem(at: annotatedURL)
        }

        // Also try with UUID-based annotated naming
        if let uuidString = path.split(separator: ".").first {
            let uuidAnnotatedURL = imagesDirectory.appendingPathComponent("annotated_\(uuidString).jpg")
            if fileManager.fileExists(atPath: uuidAnnotatedURL.path) {
                try? fileManager.removeItem(at: uuidAnnotatedURL)
            }
        }
    }

    // MARK: - Public Methods - PDF Storage

    /// Saves PDF data to disk.
    ///
    /// - Parameters:
    ///   - data: The raw PDF data to write.
    ///   - filename: The desired filename for the PDF (should include `.pdf` extension).
    /// - Returns: The full file URL of the saved PDF.
    /// - Throws: `FileStorageError.saveFailed` if writing to disk fails.
    func savePDF(_ data: Data, filename: String) throws -> URL {
        guard !filename.isEmpty else {
            throw FileStorageError.invalidFilePath
        }
        let url = pdfsDirectory.appendingPathComponent(filename)
        do {
            try data.write(to: url, options: .atomic)
        } catch {
            throw FileStorageError.saveFailed
        }
        return url
    }

    /// Deletes a PDF file from storage.
    ///
    /// - Parameter url: The file URL of the PDF to delete.
    /// - Throws: `FileStorageError.fileNotFound` if the file doesn't exist.
    ///           `FileStorageError.deleteFailed` if deletion fails.
    func deletePDF(at url: URL) throws {
        guard fileManager.fileExists(atPath: url.path) else {
            throw FileStorageError.fileNotFound
        }
        do {
            try fileManager.removeItem(at: url)
        } catch {
            throw FileStorageError.deleteFailed
        }
    }

    /// Returns the full file URL for a PDF filename.
    ///
    /// - Parameter filename: The filename of the PDF.
    /// - Returns: The complete file URL pointing to the PDFs directory.
    func pdfURL(for filename: String) -> URL {
        pdfsDirectory.appendingPathComponent(filename)
    }

    /// Loads PDF data from disk.
    ///
    /// - Parameter named: The filename of the PDF to load.
    /// - Returns: The raw PDF data, or `nil` if the file doesn't exist.
    func loadPDF(named filename: String) -> Data? {
        let url = pdfsDirectory.appendingPathComponent(filename)
        guard fileManager.fileExists(atPath: url.path) else { return nil }
        return try? Data(contentsOf: url)
    }

    /// Checks whether a PDF file exists in storage.
    ///
    /// - Parameter named: The filename of the PDF to check.
    /// - Returns: `true` if the PDF file exists.
    func pdfExists(named filename: String) -> Bool {
        let url = pdfsDirectory.appendingPathComponent(filename)
        return fileManager.fileExists(atPath: url.path)
    }

    /// Deletes a PDF file from storage by filename.
    ///
    /// - Parameter named: The filename of the PDF to delete.
    /// - Throws: `FileStorageError.fileNotFound` if the file doesn't exist.
    ///           `FileStorageError.deleteFailed` if deletion fails.
    func deletePDF(named filename: String) throws {
        let url = pdfsDirectory.appendingPathComponent(filename)
        guard fileManager.fileExists(atPath: url.path) else {
            throw FileStorageError.fileNotFound
        }
        do {
            try fileManager.removeItem(at: url)
        } catch {
            throw FileStorageError.deleteFailed
        }
    }

    /// Returns a human-readable file size string for a stored PDF.
    ///
    /// - Parameter named: The filename of the PDF.
    /// - Returns: A formatted string like "1.2 MB" or `nil` if the file doesn't exist.
    func pdfFileSize(named filename: String) -> String? {
        let url = pdfsDirectory.appendingPathComponent(filename)
        guard fileManager.fileExists(atPath: url.path),
              let attrs = try? fileManager.attributesOfItem(atPath: url.path),
              let fileSize = attrs[.size] as? Int64 else {
            return nil
        }
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }

    /// Returns the standard PDF filename for a given report ID.
    ///
    /// - Parameter reportID: The UUID of the inspection report.
    /// - Returns: A filename string like `"report_<uuid>.pdf"`.
    func pdfFilename(for reportID: UUID) -> String {
        "report_\(reportID.uuidString).pdf"
    }

    // MARK: - Public Methods - Bulk Operations

    /// Deletes all files associated with an inspection report.
    ///
    /// This includes all issue photos (originals, thumbnails, and annotated versions)
    /// as well as any generated PDF for the report.
    ///
    /// - Parameter report: The `InspectionReport` whose files should be deleted.
    /// - Throws: Propagates errors from `deleteImage(at:)` if a deletion fails critically.
    func deleteAllFiles(for report: InspectionReport) throws {
        // Delete issue photos
        if let issues = report.issues {
            for issue in issues {
                if let photos = issue.photos {
                    for photo in photos {
                        try? deleteImage(at: photo.originalImagePath)
                        if let annotatedPath = photo.annotatedImagePath {
                            try? deleteImage(at: annotatedPath)
                        }
                    }
                }
            }
        }

        // Delete PDF if one exists for this report
        let pdfFilename = "report_\(report.id.uuidString).pdf"
        let pdfURL = pdfsDirectory.appendingPathComponent(pdfFilename)
        if fileManager.fileExists(atPath: pdfURL.path) {
            try? fileManager.removeItem(at: pdfURL)
        }
    }

    // MARK: - Public Methods - Thumbnail Generation

    /// Generates a thumbnail from a full-size image using aspect-fill scaling.
    ///
    /// - Parameters:
    ///   - image: The source `UIImage`.
    ///   - size: The desired thumbnail size. Defaults to 200x200 points.
    /// - Returns: A new `UIImage` scaled and rendered to the specified size.
    func generateThumbnail(from image: UIImage, size: CGSize = CGSize(width: 200, height: 200)) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            // Aspect fill: scale to fill the entire rect
            let imageSize = image.size
            let widthRatio = size.width / imageSize.width
            let heightRatio = size.height / imageSize.height
            let scale = max(widthRatio, heightRatio)
            let scaledWidth = imageSize.width * scale
            let scaledHeight = imageSize.height * scale
            let xOffset = (size.width - scaledWidth) / 2.0
            let yOffset = (size.height - scaledHeight) / 2.0
            let drawRect = CGRect(x: xOffset, y: yOffset, width: scaledWidth, height: scaledHeight)
            image.draw(in: drawRect)
        }
    }

    /// Returns the total size in bytes of all stored files across all directories.
    ///
    /// - Returns: The total storage usage in bytes.
    func totalStorageUsage() -> UInt64 {
        var total: UInt64 = 0
        for directory in [imagesDirectory, thumbnailsDirectory, pdfsDirectory] {
            total += directorySize(at: directory)
        }
        return total
    }

    /// Clears all stored files from every managed directory.
    ///
    /// - Throws: `FileStorageError.deleteFailed` if any deletion operation fails.
    func clearAllStorage() throws {
        for directory in [imagesDirectory, thumbnailsDirectory, pdfsDirectory] {
            if fileManager.fileExists(atPath: directory.path) {
                do {
                    let contents = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
                    for url in contents {
                        try fileManager.removeItem(at: url)
                    }
                } catch {
                    throw FileStorageError.deleteFailed
                }
            }
        }
    }

    // MARK: - Private Methods

    /// Ensures all managed directories exist, creating them if necessary.
    ///
    /// - Throws: `FileStorageError.directoryCreationFailed` if any directory cannot be created.
    private func ensureDirectoriesExist() throws {
        do {
            try fileManager.createDirectory(at: imagesDirectory, withIntermediateDirectories: true, attributes: nil)
            try fileManager.createDirectory(at: thumbnailsDirectory, withIntermediateDirectories: true, attributes: nil)
            try fileManager.createDirectory(at: pdfsDirectory, withIntermediateDirectories: true, attributes: nil)
        } catch {
            throw FileStorageError.directoryCreationFailed
        }
    }

    /// Generates a unique filename using UUID.
    ///
    /// - Returns: A string suitable for use as a unique filename (without extension).
    private func uniqueFilename() -> String {
        UUID().uuidString
    }

    /// Calculates the total size of all files in a directory.
    ///
    /// - Parameter directory: The URL of the directory to measure.
    /// - Returns: Total size in bytes.
    private func directorySize(at directory: URL) -> UInt64 {
        guard fileManager.fileExists(atPath: directory.path) else { return 0 }
        guard let enumerator = fileManager.enumerator(at: directory, includingPropertiesForKeys: [.fileSizeKey]) else { return 0 }
        var total: UInt64 = 0
        for case let url as URL in enumerator {
            if let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                total += UInt64(size)
            }
        }
        return total
    }
}
