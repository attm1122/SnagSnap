import XCTest
import UIKit
@testable import SnagSnap

final class FileStorageServiceTests: XCTestCase {
    private let service = FileStorageService.shared

    func testImageSaveLoadAndDeleteRoundTrip() throws {
        let image = makeImage(color: .systemBlue)
        let paths = try service.saveImage(image)

        XCTAssertNotNil(service.loadImage(from: paths.originalPath))
        XCTAssertNotNil(service.loadThumbnail(from: paths.thumbnailPath))

        try service.deleteImage(at: paths.originalPath)
        try service.deleteImage(at: paths.thumbnailPath)

        XCTAssertNil(service.loadImage(from: paths.originalPath))
        XCTAssertNil(service.loadThumbnail(from: paths.thumbnailPath))
    }

    func testPDFSaveLoadExistsAndDeleteRoundTrip() throws {
        let filename = "test-\(UUID().uuidString).pdf"
        let data = Data("%PDF-1.4\n%SnagSnap test\n".utf8)

        let url = try service.savePDF(data, filename: filename)

        XCTAssertEqual(url.lastPathComponent, filename)
        XCTAssertTrue(service.pdfExists(named: filename))
        XCTAssertEqual(service.loadPDF(named: filename), data)
        XCTAssertNotNil(service.pdfFileSize(named: filename))

        try service.deletePDF(named: filename)
        XCTAssertFalse(service.pdfExists(named: filename))
        XCTAssertNil(service.loadPDF(named: filename))
    }

    func testPDFFilenameUsesReportIdentifier() {
        let id = UUID()
        XCTAssertEqual(service.pdfFilename(for: id), "report_\(id.uuidString).pdf")
    }

    private func makeImage(color: UIColor) -> UIImage {
        let size = CGSize(width: 32, height: 32)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
}
