import XCTest
import UIKit
@testable import SnagSnap

// MARK: - FileStorageServiceTests
// Tests for FileStorageService: image save/load, thumbnails, PDF operations, and cleanup

final class FileStorageServiceTests: XCTestCase {

    var service: FileStorageService!
    var tempDirectory: URL!

    // MARK: - Setup / Teardown

    override func setUp() {
        super.setUp()
        service = FileStorageService.shared

        // Create a unique temp directory for this test run
        let tempRoot = FileManager.default.temporaryDirectory
        tempDirectory = tempRoot.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() {
        // Clean up temp directory
        if let tempDir = tempDirectory {
            try? FileManager.default.removeItem(at: tempDir)
        }
        service = nil
        super.tearDown()
    }

    // MARK: - Helper: Create Test Image

    private func createTestImage(size: CGSize = CGSize(width: 100, height: 100), color: UIColor = .red) -> UIImage {
        UIGraphicsBeginImageContext(size)
        defer { UIGraphicsEndImageContext() }

        let context = UIGraphicsGetCurrentContext()!
        context.setFillColor(color.cgColor)
        context.fill(CGRect(origin: .zero, size: size))

        guard let image = UIGraphicsGetImageFromCurrentImageContext() else {
            XCTFail("Failed to create test image")
            return UIImage()
        }
        return image
    }

    // MARK: - Filename Generation Tests

    func testFilenameGeneration() {
        let filename1 = service.uniqueFilename()
        let filename2 = service.uniqueFilename()

        XCTAssertFalse(filename1.isEmpty, "Filename should not be empty")
        XCTAssertFalse(filename2.isEmpty, "Filename should not be empty")
        XCTAssertNotEqual(filename1, filename2, "Two generated filenames should be unique")
    }

    func testFilenameGenerationUniqueness() {
        var filenames = Set<String>()
        for _ in 0..<100 {
            let filename = service.uniqueFilename()
            XCTAssertFalse(filenames.contains(filename), "Filename should be unique: \(filename)")
            filenames.insert(filename)
        }
        XCTAssertEqual(filenames.count, 100, "All 100 filenames should be unique")
    }

    func testFilenameGenerationFormat() {
        let filename = service.uniqueFilename()
        // Typically UUID-based filenames should be valid UUID strings or contain one
        XCTAssertGreaterThan(filename.count, 8, "Filename should have meaningful length")
        // Should not contain path separators
        XCTAssertFalse(filename.contains("/"))
        XCTAssertFalse(filename.contains("\\"))
    }

    // MARK: - Image Save and Load Tests

    func testImageSaveAndLoad() throws {
        let originalImage = createTestImage(size: CGSize(width: 200, height: 200), color: .blue)

        let paths = try service.saveImage(originalImage)

        XCTAssertFalse(paths.originalPath.isEmpty, "Original path should not be empty")
        XCTAssertFalse(paths.thumbnailPath.isEmpty, "Thumbnail path should not be empty")

        // Load the original image back
        let loadedImage = service.loadImage(from: paths.originalPath)
        XCTAssertNotNil(loadedImage, "Should be able to load saved image")

        // Clean up
        try service.deleteImage(at: paths.originalPath)
        try service.deleteImage(at: paths.thumbnailPath)
    }

    func testImageRoundTrip() throws {
        let testColors: [UIColor] = [.red, .green, .blue, .yellow, .black, .white]

        for color in testColors {
            let originalImage = createTestImage(size: CGSize(width: 100, height: 100), color: color)
            let paths = try service.saveImage(originalImage)

            let loadedImage = service.loadImage(from: paths.originalPath)
            XCTAssertNotNil(loadedImage, "Should load image for color \(color)")

            // Clean up
            try service.deleteImage(at: paths.originalPath)
            try service.deleteImage(at: paths.thumbnailPath)
        }
    }

    func testImageSaveWithDifferentSizes() throws {
        let sizes = [
            CGSize(width: 1, height: 1),
            CGSize(width: 50, height: 50),
            CGSize(width: 500, height: 500),
            CGSize(width: 1000, height: 1000),
            CGSize(width: 200, height: 100),  // non-square
            CGSize(width: 100, height: 200),  // non-square
        ]

        for size in sizes {
            let image = createTestImage(size: size, color: .purple)
            let paths = try service.saveImage(image)

            XCTAssertFalse(paths.originalPath.isEmpty, "Should save \(size) image")

            let loaded = service.loadImage(from: paths.originalPath)
            XCTAssertNotNil(loaded, "Should load \(size) image")

            try service.deleteImage(at: paths.originalPath)
            try service.deleteImage(at: paths.thumbnailPath)
        }
    }

    // MARK: - Thumbnail Tests

    func testThumbnailGeneration() throws {
        let largeImage = createTestImage(size: CGSize(width: 1000, height: 1000), color: .green)
        let paths = try service.saveImage(largeImage)

        let original = service.loadImage(from: paths.originalPath)
        let thumbnail = service.loadThumbnail(from: paths.thumbnailPath)

        XCTAssertNotNil(original, "Original image should exist")
        XCTAssertNotNil(thumbnail, "Thumbnail should exist")

        // Thumbnail should be smaller than or equal to original
        if let origSize = original?.size, let thumbSize = thumbnail?.size {
            XCTAssertLessThanOrEqual(thumbSize.width, origSize.width,
                                     "Thumbnail width should be <= original width")
            XCTAssertLessThanOrEqual(thumbSize.height, origSize.height,
                                     "Thumbnail height should be <= original height")
        }

        try service.deleteImage(at: paths.originalPath)
        try service.deleteImage(at: paths.thumbnailPath)
    }

    func testThumbnailExistsAfterSave() throws {
        let image = createTestImage(size: CGSize(width: 500, height: 500))
        let paths = try service.saveImage(image)

        let thumbnail = service.loadThumbnail(from: paths.thumbnailPath)
        XCTAssertNotNil(thumbnail, "Thumbnail should be generated and loadable")

        try service.deleteImage(at: paths.originalPath)
        try service.deleteImage(at: paths.thumbnailPath)
    }

    func testThumbnailForSmallImage() throws {
        // Small images should still produce thumbnails
        let smallImage = createTestImage(size: CGSize(width: 10, height: 10), color: .cyan)
        let paths = try service.saveImage(smallImage)

        let thumbnail = service.loadThumbnail(from: paths.thumbnailPath)
        XCTAssertNotNil(thumbnail, "Thumbnail should be generated even for small images")

        try service.deleteImage(at: paths.originalPath)
        try service.deleteImage(at: paths.thumbnailPath)
    }

    // MARK: - File Deletion Tests

    func testFileDeletion() throws {
        let image = createTestImage()
        let paths = try service.saveImage(image)

        // Verify files exist
        XCTAssertNotNil(service.loadImage(from: paths.originalPath))

        // Delete original
        try service.deleteImage(at: paths.originalPath)
        let originalAfterDelete = service.loadImage(from: paths.originalPath)
        XCTAssertNil(originalAfterDelete, "Original should be nil after deletion")

        // Clean up thumbnail too
        try service.deleteImage(at: paths.thumbnailPath)
    }

    func testDeleteThumbnail() throws {
        let image = createTestImage()
        let paths = try service.saveImage(image)

        try service.deleteImage(at: paths.thumbnailPath)
        let thumbnailAfterDelete = service.loadThumbnail(from: paths.thumbnailPath)
        XCTAssertNil(thumbnailAfterDelete, "Thumbnail should be nil after deletion")

        // Clean up
        try service.deleteImage(at: paths.originalPath)
    }

    func testDeleteNonexistentFile() {
        // Deleting a non-existent file should either succeed silently or throw
        // a specific error — both are acceptable, but it should not crash
        let fakePath = tempDirectory.appendingPathComponent("nonexistent_\(UUID().uuidString).jpg").path
        XCTAssertThrowsError(try service.deleteImage(at: fakePath)) { error in
            // Expected to throw
            XCTAssertNotNil(error)
        }
    }

    // MARK: - Load Nonexistent Tests

    func testLoadNonexistentImage() {
        let fakePath = tempDirectory.appendingPathComponent("fake_\(UUID().uuidString).jpg").path
        let image = service.loadImage(from: fakePath)
        XCTAssertNil(image, "Loading nonexistent image should return nil")
    }

    func testLoadNonexistentThumbnail() {
        let fakePath = tempDirectory.appendingPathComponent("fake_thumb_\(UUID().uuidString).jpg").path
        let thumbnail = service.loadThumbnail(from: fakePath)
        XCTAssertNil(thumbnail, "Loading nonexistent thumbnail should return nil")
    }

    // MARK: - PDF Save Tests

    func testPDFSaveAndLoad() throws {
        let pdfData = createMinimalPDFData()
        let filename = "test_report_\(UUID().uuidString).pdf"

        let savedURL = try service.savePDF(pdfData, filename: filename)

        XCTAssertEqual(savedURL.lastPathComponent, filename)
        XCTAssertTrue(FileManager.default.fileExists(atPath: savedURL.path),
                      "PDF file should exist at \(savedURL.path)")

        // Verify the data round-trips
        let loadedData = try Data(contentsOf: savedURL)
        XCTAssertEqual(loadedData.count, pdfData.count, "PDF data should match")

        // Clean up
        try FileManager.default.removeItem(at: savedURL)
    }

    func testPDFSaveWithEmptyData() throws {
        let emptyData = Data()
        let filename = "empty_\(UUID().uuidString).pdf"

        // Saving empty data may or may not be allowed — test behavior
        do {
            let url = try service.savePDF(emptyData, filename: filename)
            // If it succeeds, clean up
            XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
            try FileManager.default.removeItem(at: url)
        } catch {
            // Throwing for empty data is also acceptable
            XCTAssertNotNil(error)
        }
    }

    func testPDFSaveWithLargeData() throws {
        // Create a reasonably large data blob to simulate a real PDF
        var largeData = Data()
        for i in 0..<1000 {
            largeData.append(contentsOf: "PDF content line \(i) with some padding to make it realistic. ".utf8)
        }

        let filename = "large_\(UUID().uuidString).pdf"
        let url = try service.savePDF(largeData, filename: filename)

        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        XCTAssertGreaterThan(url.lastPathComponent.count, 0)

        try FileManager.default.removeItem(at: url)
    }

    func testPDFSaveUniqueFilenames() throws {
        let pdfData = createMinimalPDFData()
        var urls = [URL]()

        for i in 0..<10 {
            let filename = "report_\(i)_\(UUID().uuidString).pdf"
            let url = try service.savePDF(pdfData, filename: filename)
            urls.append(url)
        }

        // All URLs should be unique
        let uniquePaths = Set(urls.map(\.path))
        XCTAssertEqual(uniquePaths.count, 10, "All saved PDFs should have unique paths")

        // Clean up
        for url in urls {
            try? FileManager.default.removeItem(at: url)
        }
    }

    // MARK: - Singleton Tests

    func testSharedInstance() {
        let shared1 = FileStorageService.shared
        let shared2 = FileStorageService.shared
        XCTAssertTrue(shared1 === shared2, "shared should return the same instance")
    }

    // MARK: - Edge Cases

    func testSaveImageWithTransparency() throws {
        UIGraphicsBeginImageContext(CGSize(width: 100, height: 100))
        defer { UIGraphicsEndImageContext() }

        let context = UIGraphicsGetCurrentContext()!
        context.setFillColor(UIColor.clear.cgColor)
        context.fill(CGRect(origin: .zero, size: CGSize(width: 100, height: 100)))

        guard let transparentImage = UIGraphicsGetImageFromCurrentImageContext() else {
            XCTFail("Failed to create transparent image")
            return
        }

        let paths = try service.saveImage(transparentImage)
        XCTAssertFalse(paths.originalPath.isEmpty)

        let loaded = service.loadImage(from: paths.originalPath)
        XCTAssertNotNil(loaded)

        try service.deleteImage(at: paths.originalPath)
        try service.deleteImage(at: paths.thumbnailPath)
    }

    func testMultipleSavesProduceDifferentPaths() throws {
        let image = createTestImage()
        let paths1 = try service.saveImage(image)
        let paths2 = try service.saveImage(image)

        XCTAssertNotEqual(paths1.originalPath, paths2.originalPath,
                          "Consecutive saves should produce different paths")
        XCTAssertNotEqual(paths1.thumbnailPath, paths2.thumbnailPath,
                          "Consecutive saves should produce different thumbnail paths")

        try service.deleteImage(at: paths1.originalPath)
        try service.deleteImage(at: paths1.thumbnailPath)
        try service.deleteImage(at: paths2.originalPath)
        try service.deleteImage(at: paths2.thumbnailPath)
    }

    // MARK: - Private Helpers

    private func createMinimalPDFData() -> Data {
        // Create a minimal valid PDF data blob
        let pdfHeader = "%PDF-1.4\n"
        let pdfBody = "1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n"
        let pdfFooter = "%%EOF\n"
        var data = Data()
        data.append(pdfHeader.data(using: .utf8)!)
        data.append(pdfBody.data(using: .utf8)!)
        data.append(pdfFooter.data(using: .utf8)!)
        return data
    }
}
