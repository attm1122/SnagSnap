import UIKit

// MARK: - Image Manipulation

extension UIImage {
    /// Resize the image to fit within the given size while maintaining aspect ratio.
    ///
    /// - Parameters:
    ///   - targetSize: The maximum width and height.
    ///   - scale: The image scale (default: device scale).
    /// - Returns: Resized image, or nil if resizing fails.
    func resized(toFit targetSize: CGSize, scale: CGFloat = UIScreen.main.scale) -> UIImage? {
        let widthRatio = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height
        let ratio = min(widthRatio, heightRatio)

        guard ratio < 1.0 else { return self }

        let newSize = CGSize(
            width: size.width * ratio,
            height: size.height * ratio
        )

        return resized(to: newSize, scale: scale)
    }

    /// Resize the image to fill the given size while maintaining aspect ratio (may crop).
    ///
    /// - Parameters:
    ///   - targetSize: The target width and height.
    ///   - scale: The image scale.
    /// - Returns: Resized and cropped image, or nil if fails.
    func resized(toFill targetSize: CGSize, scale: CGFloat = UIScreen.main.scale) -> UIImage? {
        let widthRatio = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height
        let ratio = max(widthRatio, heightRatio)

        let newSize = CGSize(
            width: size.width * ratio,
            height: size.height * ratio
        )

        let format = UIGraphicsImageRendererFormat()
        format.scale = scale

        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        return renderer.image { context in
            let origin = CGPoint(
                x: (targetSize.width - newSize.width) / 2,
                y: (targetSize.height - newSize.height) / 2
            )
            self.draw(in: CGRect(origin: origin, size: newSize))
        }
    }

    /// Resize the image to an exact size (may distort aspect ratio).
    ///
    /// - Parameters:
    ///   - targetSize: The exact target size.
    ///   - scale: The image scale.
    /// - Returns: Resized image, or nil if fails.
    func resized(to targetSize: CGSize, scale: CGFloat = UIScreen.main.scale) -> UIImage? {
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale

        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }

    /// Scale the image by a factor.
    ///
    /// - Parameters:
    ///   - factor: Scale multiplier (e.g., 0.5 for half size).
    ///   - scale: The image scale.
    /// - Returns: Scaled image, or nil if fails.
    func scaled(by factor: CGFloat, scale: CGFloat = UIScreen.main.scale) -> UIImage? {
        let newSize = CGSize(width: size.width * factor, height: size.height * factor)
        return resized(to: newSize, scale: scale)
    }

    // MARK: - Compression

    /// Compress the image to a target file size.
    ///
    /// - Parameters:
    ///   - maxSizeKB: Target maximum file size in kilobytes.
    ///   - allowedTypes: UTTypes to try (jpeg, heic).
    /// - Returns: Compressed image data, or nil if compression fails.
    func compressed(toMaxSizeKB maxSizeKB: Int, compressionQuality: CGFloat = 0.9) -> Data? {
        let maxBytes = maxSizeKB * 1024

        var quality = compressionQuality
        var imageData = self.jpegData(compressionQuality: quality)

        // Iteratively reduce quality until under max size
        while let data = imageData, data.count > maxBytes, quality > 0.1 {
            quality -= 0.1
            imageData = self.jpegData(compressionQuality: quality)
        }

        // If still too large, resize and try again
        if let data = imageData, data.count > maxBytes {
            let scaleFactor = sqrt(CGFloat(maxBytes) / CGFloat(data.count))
            if let resized = self.scaled(by: scaleFactor),
               let resizedData = resized.jpegData(compressionQuality: quality) {
                return resizedData.count <= maxBytes ? resizedData : resized.jpegData(compressionQuality: 0.7)
            }
        }

        return imageData
    }

    /// Compress to JPEG data with a specific quality.
    func jpegData(quality: CGFloat) -> Data? {
        jpegData(compressionQuality: max(0.0, min(1.0, quality)))
    }

    // MARK: - Rotation

    /// Rotate the image by a specified angle in degrees.
    ///
    /// - Parameter degrees: Rotation angle in degrees (positive = clockwise).
    /// - Returns: Rotated image, or nil if rotation fails.
    func rotated(by degrees: CGFloat) -> UIImage? {
        let radians = degrees * .pi / 180

        let rotatedViewBox = CGRect(
            x: 0, y: 0,
            width: size.width,
            height: size.height
        )
        .applying(CGAffineTransform(rotationAngle: radians))

        let rotatedSize = CGSize(
            width: abs(rotatedViewBox.width),
            height: abs(rotatedViewBox.height)
        )

        let format = UIGraphicsImageRendererFormat()
        format.scale = scale

        let renderer = UIGraphicsImageRenderer(size: rotatedSize, format: format)
        return renderer.image { _ in
            let context = UIGraphicsGetCurrentContext()
            context?.translateBy(x: rotatedSize.width / 2, y: rotatedSize.height / 2)
            context?.rotate(by: radians)
            draw(in: CGRect(
                x: -size.width / 2,
                y: -size.height / 2,
                width: size.width,
                height: size.height
            ))
        }
    }

    /// Rotate image 90 degrees clockwise.
    func rotated90Clockwise() -> UIImage? {
        rotated(by: 90)
    }

    /// Rotate image 90 degrees counterclockwise.
    func rotated90CounterClockwise() -> UIImage? {
        rotated(by: -90)
    }

    /// Rotate image 180 degrees.
    func rotated180() -> UIImage? {
        rotated(by: 180)
    }

    // MARK: - Cropping

    /// Crop the image to a specified rect.
    ///
    /// - Parameter rect: The rect to crop to, in image coordinates.
    /// - Returns: Cropped image, or nil if fails.
    func cropped(to rect: CGRect) -> UIImage? {
        guard let cgImage = self.cgImage else { return nil }

        let scaledRect = CGRect(
            x: rect.origin.x * scale,
            y: rect.origin.y * scale,
            width: rect.size.width * scale,
            height: rect.size.height * scale
        )

        guard let croppedCGImage = cgImage.cropping(to: scaledRect) else { return nil }
        return UIImage(cgImage: croppedCGImage, scale: scale, orientation: imageOrientation)
    }

    /// Crop to a square from the center.
    func croppedToSquare() -> UIImage? {
        let minDimension = min(size.width, size.height)
        let rect = CGRect(
            x: (size.width - minDimension) / 2,
            y: (size.height - minDimension) / 2,
            width: minDimension,
            height: minDimension
        )
        return cropped(to: rect)
    }

    // MARK: - Format Conversion

    /// Convert to PNG data.
    var pngData: Data? {
        pngData()
    }

    /// Get file size in bytes for JPEG at given quality.
    func jpegFileSize(quality: CGFloat = 0.9) -> Int? {
        jpegData(compressionQuality: quality)?.count
    }

    /// Get file size as a human-readable string.
    func formattedFileSize(quality: CGFloat = 0.9) -> String? {
        guard let bytes = jpegFileSize(quality: quality) else { return nil }
        return formatFileSize(Int64(bytes))
    }

    // MARK: - Drawing / Annotation

    /// Draw a filled circle on the image.
    ///
    /// - Parameters:
    ///   - center: Center point of the circle.
    ///   - radius: Radius in points.
    ///   - color: Fill color.
    /// - Returns: New image with the circle drawn.
    func drawCircle(center: CGPoint, radius: CGFloat, color: UIColor) -> UIImage? {
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale

        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: size))
            let path = UIBezierPath(arcCenter: center, radius: radius, startAngle: 0, endAngle: .pi * 2, clockwise: true)
            color.setFill()
            path.fill()
        }
    }

    /// Draw text on the image.
    ///
    /// - Parameters:
    ///   - text: Text to draw.
    ///   - point: Position for the text.
    ///   - font: Font to use.
    ///   - color: Text color.
    /// - Returns: New image with text drawn.
    func drawText(_ text: String, at point: CGPoint, font: UIFont = .systemFont(ofSize: 16), color: UIColor = .white) -> UIImage? {
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale

        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: size))
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: color
            ]
            text.draw(at: point, withAttributes: attributes)
        }
    }

    // MARK: - Properties

    /// Dimensions as a human-readable string.
    var dimensionsString: String {
        "\(Int(size.width)) x \(Int(size.height))"
    }

    /// Megapixel count.
    var megapixels: Double {
        Double(size.width * size.height) / 1_000_000.0
    }

    /// Check if the image is in portrait orientation.
    var isPortrait: Bool {
        size.height > size.width
    }

    /// Check if the image is in landscape orientation.
    var isLandscape: Bool {
        size.width > size.height
    }

    /// Check if the image is square.
    var isSquare: Bool {
        abs(size.width - size.height) < 1
    }
}

// MARK: - UIImage Creation

extension UIImage {
    /// Create a solid color image.
    ///
    /// - Parameters:
    ///   - color: The fill color.
    ///   - size: Image dimensions.
    /// - Returns: Solid color image.
    static func from(color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) -> UIImage? {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1

        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
}
