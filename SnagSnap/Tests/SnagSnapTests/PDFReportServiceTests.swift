import PDFKit
import XCTest
@testable import SnagSnap

final class PDFReportServiceTests: XCTestCase {
    func testGeneratePDFProducesReadableDocument() throws {
        let report = makeReport()
        let data = try PDFReportService.shared.generatePDF(for: report)
        let document = PDFDocument(data: data)

        XCTAssertGreaterThan(data.count, 0)
        XCTAssertNotNil(document)
        XCTAssertEqual(document?.pageCount, 3)
    }

    func testExportSettingsCanOmitCoverAndSummary() throws {
        let report = makeReport()
        var settings = PDFExportSettings.default
        settings.includeCoverPage = false
        settings.includeSummary = false

        let data = try PDFReportService.shared.generatePDF(for: report, settings: settings)
        let document = PDFDocument(data: data)

        XCTAssertEqual(document?.pageCount, 1)
    }

    func testPhotoGridLayoutRestartsRowsAfterPageBreak() {
        let layout = PDFPhotoGridLayout(
            pageHeight: 842,
            topY: 650,
            bottomMargin: 50,
            contentWidth: 495,
            horizontalMargin: 50,
            photoSize: 130,
            rowSpacing: 10,
            photosPerRow: 3,
            continuedTopY: 80
        )

        let placements = layout.placements(forPhotoCount: 5)

        XCTAssertEqual(placements.map(\.pageOffset), [0, 0, 0, 1, 1])
        XCTAssertEqual(placements[3].rect.minY, 80)
        XCTAssertEqual(placements[4].rect.minY, 80)
        XCTAssertLessThanOrEqual(placements[4].rect.maxY, 842 - 50)
    }

    func testShareServiceWritesNamedTemporaryPDFFile() throws {
        let data = Data("%PDF-1.4\n%SnagSnap test\n".utf8)

        let url = try ShareService.shared.temporaryPDFFile(data, reportTitle: "Final Inspection / Unit 4")

        XCTAssertEqual(url.pathExtension, "pdf")
        XCTAssertTrue(url.lastPathComponent.contains("Final-Inspection-Unit-4"))
        XCTAssertEqual(try Data(contentsOf: url), data)
        try? FileManager.default.removeItem(at: url)
    }

    private func makeReport() -> InspectionReport {
        let report = InspectionReport(
            title: "Inspection",
            propertyName: "Flat 4",
            propertyAddress: "1 Test Street",
            reportType: .general,
            inspectorName: "Inspector"
        )
        let issue = InspectionIssue(
            title: "Cracked tile",
            notes: "Tile cracked near the kitchen sink.",
            severity: .high,
            status: .open
        )
        report.issues = [issue]
        return report
    }
}
