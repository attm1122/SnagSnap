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
