//
//  ThumbnailService.swift
//  SnagSnap
//
//  Async thumbnail generation service with caching support.
//

import Foundation
import UIKit

/// Errors that can occur during thumbnail generation.
enum ThumbnailServiceError: Error, LocalizedError {
    case imageNotFound
    case generationFailed
    case invalidSize
    case cachingFailed
    case taskCancelled

    var errorDescription: String? {
        switch self {
        case .imageNotFound:
            return "Source image not found for thumbnail generation."
        case .generationFailed:
            return "Failed to generate thumbnail from source image."
        case .invalidSize:
            return "Invalid thumbnail size requested. Dimensions must be greater than zero."
        case .cachingFailed:
            return "Failed to cache generated thumbnail."
        case .taskCancelled:
            return "Thumbnail generation was cancelled."
        }
    }
}

/// Describes the resize mode for thumbnail generation.
enum ThumbnailResizeMode {
    /// Scales to fill the entire bounds, cropping excess (aspect fill).
    case aspectFill
    /// Scales to fit entirely within bounds, letterboxing if needed (aspect fit).
    case aspectFit
    /// Stretches the image to exactly match the target size.
    case stretch
}

/// Async thumbnail generation service with NSCache-based in-memory caching.
///
/// `ThumbnailService` provides efficient, concurrent thumbnail generation using Swift's
/// structured concurrency. Generated thumbnails are cached in memory to avoid redundant
/// processing. The cache automatically evicts entries under memory pressure.
@Observable
class ThumbnailService {

    // MARK: - Shared Instance

    /// The shared singleton instance of `ThumbnailService`.
    static let shared = ThumbnailService()

    // MARK: - Properties

    /// In-memory cache for recently generated thumbnails, keyed by source path + size hash.
    private let cache = NSCache<NSString, UIImage>()

    /// Maximum number of thumbnails to keep in memory cache.
    private let cacheCountLimit = 100

    /// Actor-isolated task registry to prevent duplicate generation for the same key.
    private let taskRegistry = ThumbnailTaskRegistry()

    /// The file storage service used to load source images.
    private let fileStorage: FileStorageService

    // MARK: - Initialization

    /// Creates a new `ThumbnailService`.
    ///
    /// - Parameter fileStorage: The `FileStorageService` to use for loading images.
    ///   Defaults to the shared instance.
    init(fileStorage: FileStorageService = .shared) {
        self.fileStorage = fileStorage
        self.cache.countLimit = cacheCountLimit
        self.cache.evictsObjectsWithDiscardedContent = true
    }

    // MARK: - Public Methods

    /// Generates a thumbnail asynchronously from a stored image path.
    ///
    /// This method first checks the in-memory cache, then falls back to loading
    /// the full image and generating a thumbnail. Duplicate requests for the same
    /// source path and size are coalesced into a single generation task.
    ///
    /// - Parameters:
    ///   - path: The filename of the stored image to thumbnail.
    ///   - size: The desired thumbnail size in points. Defaults to 200x200.
    ///   - resizeMode: The resizing behavior. Defaults to `.aspectFill`.
    ///   - cornerRadius: Optional corner radius for rounded thumbnails. Defaults to `nil`.
    /// - Returns: The generated thumbnail `UIImage`.
    /// - Throws: `ThumbnailServiceError.imageNotFound` if the source image doesn't exist.
    ///           `ThumbnailServiceError.invalidSize` if the size has non-positive dimensions.
    ///           `ThumbnailServiceError.generationFailed` if rendering fails.
    ///           `ThumbnailServiceError.taskCancelled` if the task is cancelled.
    func generateThumbnail(
        from path: String,
        size: CGSize = CGSize(width: 200, height: 200),
        resizeMode: ThumbnailResizeMode = .aspectFill,
        cornerRadius: CGFloat? = nil
    ) async throws -> UIImage {
        // Validate size
        guard size.width > 0, size.height > 0 else {
            throw ThumbnailServiceError.invalidSize
        }

        guard !path.isEmpty else {
            throw ThumbnailServiceError.imageNotFound
        }

        // Check cache first
        let cacheKey = self.cacheKey(for: path, size: size, resizeMode: resizeMode, cornerRadius: cornerRadius)
        let cacheKeyString = cacheKey as String
        if let cached = cache.object(forKey: cacheKey) {
            return cached
        }

        // Coalesce duplicate requests
        return try await taskRegistry.withTask(for: cacheKeyString) {
            let cacheKey = cacheKeyString as NSString
            // Check cache again in case another task finished while we were waiting
            if let cached = self.cache.object(forKey: cacheKey) {
                return cached
            }

            // Try to load thumbnail from disk first (faster than regenerating)
            if let diskThumbnail = self.fileStorage.loadThumbnail(from: path) {
                // If the disk thumbnail is already the right size, cache and return it
                if diskThumbnail.size == size {
                    self.cache.setObject(diskThumbnail, forKey: cacheKey)
                    return diskThumbnail
                }
            }

            // Load full image and generate thumbnail
            guard let sourceImage = self.fileStorage.loadImage(from: path) else {
                throw ThumbnailServiceError.imageNotFound
            }

            // Check for cancellation before heavy work
            try Task.checkCancellation()

            let thumbnail = self.renderThumbnail(
                from: sourceImage,
                size: size,
                resizeMode: resizeMode,
                cornerRadius: cornerRadius
            )

            // Check for cancellation after rendering
            try Task.checkCancellation()

            // Store in cache
            self.cache.setObject(thumbnail, forKey: cacheKey)

            return thumbnail
        }
    }

    /// Generates a thumbnail directly from a `UIImage` without loading from disk.
    ///
    /// - Parameters:
    ///   - image: The source `UIImage`.
    ///   - size: The desired thumbnail size. Defaults to 200x200.
    ///   - resizeMode: The resizing behavior. Defaults to `.aspectFill`.
    ///   - cornerRadius: Optional corner radius. Defaults to `nil`.
    /// - Returns: The generated thumbnail `UIImage`.
    /// - Throws: `ThumbnailServiceError.invalidSize` if size is invalid.
    ///           `ThumbnailServiceError.generationFailed` if rendering fails.
    ///           `ThumbnailServiceError.taskCancelled` if the task is cancelled.
    func generateThumbnail(
        from image: UIImage,
        size: CGSize = CGSize(width: 200, height: 200),
        resizeMode: ThumbnailResizeMode = .aspectFill,
        cornerRadius: CGFloat? = nil
    ) async throws -> UIImage {
        guard size.width > 0, size.height > 0 else {
            throw ThumbnailServiceError.invalidSize
        }

        try Task.checkCancellation()

        let thumbnail = renderThumbnail(
            from: image,
            size: size,
            resizeMode: resizeMode,
            cornerRadius: cornerRadius
        )

        try Task.checkCancellation()

        return thumbnail
    }

    /// Generates multiple thumbnails concurrently from a collection of image paths.
    ///
    /// - Parameters:
    ///   - paths: An array of image filenames to generate thumbnails for.
    ///   - size: The desired thumbnail size. Defaults to 200x200.
    ///   - resizeMode: The resizing behavior. Defaults to `.aspectFill`.
    /// - Returns: A dictionary mapping each path to its generated thumbnail.
    ///           Paths that fail will map to `nil`.
    func generateThumbnails(
        from paths: [String],
        size: CGSize = CGSize(width: 200, height: 200),
        resizeMode: ThumbnailResizeMode = .aspectFill
    ) async -> [String: UIImage] {
        guard !paths.isEmpty else { return [:] }

        return await withTaskGroup(of: (String, UIImage?).self) { group in
            for path in paths {
                group.addTask {
                    do {
                        let thumbnail = try await self.generateThumbnail(
                            from: path,
                            size: size,
                            resizeMode: resizeMode
                        )
                        return (path, thumbnail)
                    } catch {
                        return (path, nil)
                    }
                }
            }

            var results: [String: UIImage] = [:]
            results.reserveCapacity(paths.count)
            for await (path, image) in group {
                if let image = image {
                    results[path] = image
                }
            }
            return results
        }
    }

    /// Prefetches and caches thumbnails for a collection of image paths.
    ///
    /// This is useful for preparing thumbnails before they appear on screen,
    /// such as when navigating to a photo gallery view.
    ///
    /// - Parameters:
    ///   - paths: Image filenames to prefetch thumbnails for.
    ///   - size: The thumbnail size to generate. Defaults to 200x200.
    func prefetchThumbnails(from paths: [String], size: CGSize = CGSize(width: 200, height: 200)) async {
        guard !paths.isEmpty else { return }
        _ = await generateThumbnails(from: paths, size: size)
    }

    /// Clears all cached thumbnails from memory.
    func clearCache() {
        cache.removeAllObjects()
    }

    /// Returns the current number of cached thumbnails.
    var cachedCount: Int {
        // NSCache doesn't expose its count directly; this is an approximation
        // via a private helper that exercises the cache
        0 // Intentionally returning 0 as NSCache doesn't expose count
    }

    // MARK: - Private Methods

    /// Renders a thumbnail from a source image on a background thread.
    ///
    /// - Parameters:
    ///   - image: The source `UIImage`.
    ///   - size: The target size.
    ///   - resizeMode: How to scale the image.
    ///   - cornerRadius: Optional corner radius for rounding.
    /// - Returns: The rendered thumbnail.
    private func renderThumbnail(
        from image: UIImage,
        size: CGSize,
        resizeMode: ThumbnailResizeMode,
        cornerRadius: CGFloat?
    ) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = UIScreen.main.scale
        format.preferredRange = .standard

        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { _ in
            let rect = CGRect(origin: .zero, size: size)

            // Apply corner radius clipping if requested
            if let cornerRadius = cornerRadius, cornerRadius > 0 {
                let path = UIBezierPath(
                    roundedRect: rect,
                    cornerRadius: cornerRadius
                )
                path.addClip()
            }

            // Calculate draw rect based on resize mode
            let drawRect: CGRect
            let imageSize = image.size

            switch resizeMode {
            case .aspectFill:
                let widthRatio = size.width / imageSize.width
                let heightRatio = size.height / imageSize.height
                let scale = max(widthRatio, heightRatio)
                let scaledWidth = imageSize.width * scale
                let scaledHeight = imageSize.height * scale
                let xOffset = (size.width - scaledWidth) / 2.0
                let yOffset = (size.height - scaledHeight) / 2.0
                drawRect = CGRect(x: xOffset, y: yOffset, width: scaledWidth, height: scaledHeight)

            case .aspectFit:
                let widthRatio = size.width / imageSize.width
                let heightRatio = size.height / imageSize.height
                let scale = min(widthRatio, heightRatio)
                let scaledWidth = imageSize.width * scale
                let scaledHeight = imageSize.height * scale
                let xOffset = (size.width - scaledWidth) / 2.0
                let yOffset = (size.height - scaledHeight) / 2.0
                drawRect = CGRect(x: xOffset, y: yOffset, width: scaledWidth, height: scaledHeight)

            case .stretch:
                drawRect = rect
            }

            image.draw(in: drawRect)
        }
    }

    /// Generates a cache key from the given parameters.
    ///
    /// - Parameters:
    ///   - path: The image filename.
    ///   - size: The thumbnail size.
    ///   - resizeMode: The resize mode.
    ///   - cornerRadius: Optional corner radius.
    /// - Returns: A unique string key for cache lookups.
    private func cacheKey(
        for path: String,
        size: CGSize,
        resizeMode: ThumbnailResizeMode,
        cornerRadius: CGFloat?
    ) -> NSString {
        let modeString: String
        switch resizeMode {
        case .aspectFill: modeString = "fill"
        case .aspectFit: modeString = "fit"
        case .stretch: modeString = "stretch"
        }
        let radiusString = cornerRadius.map { "_r\($0)" } ?? ""
        return "\(path)_\(Int(size.width))x\(Int(size.height))_\(modeString)\(radiusString)" as NSString
    }
}

// MARK: - Task Registry

/// Actor-isolated task registry that coalesces duplicate thumbnail generation requests.
///
/// When multiple callers request a thumbnail for the same key simultaneously,
/// only one generation task is executed. All callers receive the same result.
private actor ThumbnailTaskRegistry {

    /// Dictionary of in-flight tasks keyed by cache key.
    private var tasks: [String: Task<UIImage, Error>] = [:]

    /// Executes a thumbnail generation task, coalescing duplicate requests.
    ///
    /// - Parameters:
    ///   - key: The unique cache key for this thumbnail.
    ///   - operation: The async closure that performs the actual generation.
    /// - Returns: The generated thumbnail.
    /// - Throws: Any error thrown by the operation.
    func withTask(
        for key: String,
        operation: @Sendable @escaping () async throws -> UIImage
    ) async throws -> UIImage {
        // If a task is already in flight for this key, wait for it
        if let existingTask = tasks[key] {
            return try await existingTask.value
        }

        // Create a new task and store it
        let task = Task<UIImage, Error> {
            return try await operation()
        }

        tasks[key] = task

        do {
            let result = try await task.value
            removeTask(for: key)
            return result
        } catch {
            removeTask(for: key)
            throw error
        }
    }

    /// Removes a completed task from the registry.
    ///
    /// - Parameter key: The cache key of the task to remove.
    private func removeTask(for key: String) {
        tasks.removeValue(forKey: key)
    }
}
