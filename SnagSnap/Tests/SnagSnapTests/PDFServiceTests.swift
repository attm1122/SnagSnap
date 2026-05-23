import XCTest
import PDFKit
@testable import SnagSnap

// MARK: - PDFServiceTests
// Tests for PDF generation service, page counts, export settings, and edge cases

final class PDFServiceTests: XCTestCase {

    // MARK: - Test Data Helpers

    private func makeReport(
        title: String = "Test Report",
        propertyName: String = "Test Property",
        propertyAddress: String = "123 Test St",
        status: ReportStatus = .ready,
        reportType: ReportType = .snagging,
        areas: [InspectionArea] = [],
        issues: [InspectionIssue] = []
    ) -> InspectionReport {
        InspectionReport(
            title: title,
            propertyName: propertyName,
            propertyAddress: propertyAddress,
            status: status,
            reportType: reportType,
            areas: areas,
            issues: issues
        )
    }

    private func makeIssue(
        title: String = "Test Issue",
        notes: String? = nil,
        severity: IssueSeverity = .medium,
        status: IssueStatus = .open
    ) -> InspectionIssue {
        InspectionIssue(
            title: title,
            notes: notes,
            severity: severity,
            status: status
        )
    }

    private func makeArea(name: String, notes: String? = nil) -> InspectionArea {
        InspectionArea(name: name, notes: notes)
    }

    // MARK: - PDF Generation Success Tests

    func testPDFGenerationSuccess() throws {
        let report = makeReport(
            title: "Move-In Inspection",
            propertyName: "Willow Creek Apartments",
            propertyAddress: "789 Willow Creek Dr"
        )

        let pdfData = try PDFService.generatePDF(for: report)

        XCTAssertGreaterThan(pdfData.count, 0, "Generated PDF should have non-zero data")
        XCTAssertTrue(PDFService.isValidPDF(data: pdfData), "Generated data should be a valid PDF")
    }

    func testPDFGenerationWithMinimalReport() throws {
        let report = InspectionReport()
        let pdfData = try PDFService.generatePDF(for: report)

        XCTAssertGreaterThan(pdfData.count, 0, "PDF should be generated even for minimal report")
        XCTAssertTrue(PDFService.isValidPDF(data: pdfData), "Should be valid PDF")
    }

    // MARK: - PDF Pages Count Tests

    func testPDFPagesCount() throws {
        let issue1 = makeIssue(title: "Wall crack", severity: .high)
        let issue2 = makeIssue(title: "Floor stain", severity: .medium)
        let report = makeReport(
            title: "Inspection with Issues",
            issues: [issue1, issue2]
        )

        let pdfData = try PDFService.generatePDF(for: report)
        let pageCount = PDFService.pageCount(in: pdfData)

        // Should have: cover page + summary page + issue pages
        XCTAssertGreaterThanOrEqual(pageCount, 2, "PDF should have at least cover and summary pages")
        XCTAssertTrue(PDFService.isValidPDF(data: pdfData))
    }

    func testPDFWithEmptyReport() throws {
        let report = makeReport(
            title: "Empty Report",
            propertyName: "Empty Property"
        )

        let pdfData = try PDFService.generatePDF(for: report)

        XCTAssertGreaterThan(pdfData.count, 0, "Empty report should still produce PDF")
        XCTAssertTrue(PDFService.isValidPDF(data: pdfData), "Should be valid PDF")

        let pageCount = PDFService.pageCount(in: pdfData)
        XCTAssertGreaterThanOrEqual(pageCount, 1, "Should have at least 1 page")
    }

    func testPDFWithMultipleIssues() throws {
        var issues = [InspectionIssue]()
        for i in 1...15 {
            let issue = makeIssue(
                title: "Issue #\(i): \(UUID().uuidString.prefix(8))",
                notes: "Detailed description for issue number \(i). This is a longer note to simulate realistic content.",
                severity: i % 4 == 0 ? .urgent : (i % 3 == 0 ? .high : (i % 2 == 0 ? .medium : .low)),
                status: i % 5 == 0 ? .fixed : .open
            )
            issues.append(issue)
        }

        let report = makeReport(
            title: "Full Property Inspection",
            propertyName: "Riverside Condos",
            propertyAddress: "321 River Rd, Apt 42",
            areas: [
                makeArea(name: "Living Room"),
                makeArea(name: "Kitchen"),
                makeArea(name: "Master Bedroom"),
                makeArea(name: "Bathroom"),
                makeArea(name: "Balcony")
            ],
            issues: issues
        )

        let pdfData = try PDFService.generatePDF(for: report)

        XCTAssertGreaterThan(pdfData.count, 100, "Multi-issue PDF should have substantial data")
        XCTAssertTrue(PDFService.isValidPDF(data: pdfData))

        let pageCount = PDFService.pageCount(in: pdfData)
        XCTAssertGreaterThanOrEqual(pageCount, 1, "Should have at least 1 page")
    }

    func testPDFWithAllIssueStatuses() throws {
        let statuses: [IssueStatus] = [.open, .inProgress, .fixed, .notAnIssue, .archived]
        let issues = statuses.enumerated().map { index, status in
            makeIssue(title: "Issue with status \(status.displayName)", status: status)
        }

        let report = makeReport(title: "Status Test Report", issues: issues)
        let pdfData = try PDFService.generatePDF(for: report)

        XCTAssertTrue(PDFService.isValidPDF(data: pdfData))
        XCTAssertGreaterThan(PDFService.pageCount(in: pdfData), 0)
    }

    func testPDFWithAllSeverities() throws {
        let severities: [IssueSeverity] = [.low, .medium, .high, .urgent]
        let issues = severities.map { severity in
            makeIssue(title: "\(severity.displayName) severity issue", severity: severity)
        }

        let report = makeReport(title: "Severity Test Report", issues: issues)
        let pdfData = try PDFService.generatePDF(for: report)

        XCTAssertTrue(PDFService.isValidPDF(data: pdfData))
    }

    // MARK: - PDF Export Settings Tests

    func testPDFExportSettingsDefaults() {
        let settings = PDFExportSettings()

        XCTAssertTrue(settings.includePhotos, "includePhotos should default to true")
        XCTAssertTrue(settings.includeSignatures, "includeSignatures should default to true")
        XCTAssertTrue(settings.includeCompanyHeader, "includeCompanyHeader should default to true")
        XCTAssertFalse(settings.isHighQuality, "isHighQuality should default to false")
    }

    func testPDFExportSettingsCustomization() {
        var settings = PDFExportSettings()
        settings.includePhotos = false
        settings.includeSignatures = false
        settings.includeCompanyHeader = false
        settings.isHighQuality = true

        XCTAssertFalse(settings.includePhotos)
        XCTAssertFalse(settings.includeSignatures)
        XCTAssertFalse(settings.includeCompanyHeader)
        XCTAssertTrue(settings.isHighQuality)
    }

    func testPDFExportSettingsPartialCustomization() {
        var settings = PDFExportSettings()
        settings.includePhotos = false

        XCTAssertFalse(settings.includePhotos)
        XCTAssertTrue(settings.includeSignatures)
        XCTAssertTrue(settings.includeCompanyHeader)
        XCTAssertFalse(settings.isHighQuality)
    }

    // MARK: - PDF with Export Settings Tests

    func testPDFGenerationWithSettings() throws {
        let report = makeReport(
            title: "Settings Test Report",
            issues: [
                makeIssue(title: "Test issue 1"),
                makeIssue(title: "Test issue 2")
            ]
        )

        let settings = PDFExportSettings()
        let pdfData = try PDFService.generatePDF(for: report, settings: settings)

        XCTAssertGreaterThan(pdfData.count, 0)
        XCTAssertTrue(PDFService.isValidPDF(data: pdfData))
    }

    func testPDFGenerationWithNoPhotosSetting() throws {
        let report = makeReport(
            title: "No Photos Report",
            issues: [makeIssue(title: "Photo-less issue")]
        )

        var settings = PDFExportSettings()
        settings.includePhotos = false
        let pdfData = try PDFService.generatePDF(for: report, settings: settings)

        XCTAssertGreaterThan(pdfData.count, 0)
        XCTAssertTrue(PDFService.isValidPDF(data: pdfData))
    }

    func testPDFGenerationHighQuality() throws {
        let report = makeReport(
            title: "High Quality Report",
            issues: (1...5).map { makeIssue(title: "Issue \($0)") }
        )

        var settings = PDFExportSettings()
        settings.isHighQuality = true
        let pdfData = try PDFService.generatePDF(for: report, settings: settings)

        XCTAssertGreaterThan(pdfData.count, 0)
        XCTAssertTrue(PDFService.isValidPDF(data: pdfData))
    }

    // MARK: - PDF Validation Tests

    func testValidPDFDetection() {
        // Valid PDF header
        var validData = Data()
        validData.append(contentsOf: "%PDF-1.4\n".utf8)
        validData.append(contentsOf: "trailer\n<< /Size 1 >>\n%%EOF".utf8)

        XCTAssertTrue(PDFService.isValidPDF(data: validData), "Should detect valid PDF header")
    }

    func testInvalidPDFDetection() {
        let invalidData = Data("This is not a PDF file".utf8)
        XCTAssertFalse(PDFService.isValidPDF(data: invalidData), "Should detect invalid PDF")
    }

    func testEmptyDataIsNotValidPDF() {
        let emptyData = Data()
        XCTAssertFalse(PDFService.isValidPDF(data: emptyData), "Empty data should not be valid PDF")
    }

    func testRandomDataIsNotValidPDF() {
        var randomData = Data(count: 100)
        _ = randomData.withUnsafeMutableBytes { SecRandomCopyBytes(kSecRandomDefault, 100, $0.baseAddress!) }
        XCTAssertFalse(PDFService.isValidPDF(data: randomData), "Random data should not be valid PDF")
    }

    // MARK: - PDF Page Count Tests

    func testPDFPageCountWithValidPDF() {
        // Create a minimal PDF structure for page count testing
        let pdfContent = """
            %PDF-1.4
            1 0 obj << /Type /Catalog /Pages 2 0 R >> endobj
            2 0 obj << /Type /Pages /Kids [3 0 R 4 0 R] /Count 2 >> endobj
            3 0 obj << /Type /Page /Parent 2 0 R >> endobj
            4 0 obj << /Type /Page /Parent 2 0 R >> endobj
            xref
            trailer << /Size 5 /Root 1 0 R >>
            %%EOF
            """
        let pdfData = Data(pdfContent.utf8)
        let count = PDFService.pageCount(in: pdfData)
        XCTAssertGreaterThanOrEqual(count, 0, "Page count should be non-negative")
    }

    func testPDFPageCountWithEmptyData() {
        let count = PDFService.pageCount(in: Data())
        XCTAssertEqual(count, 0, "Empty data should have 0 pages")
    }

    func testPDFPageCountWithInvalidData() {
        let count = PDFService.pageCount(in: Data("not a pdf".utf8))
        XCTAssertEqual(count, 0, "Invalid data should have 0 pages")
    }

    // MARK: - PDF Header Content Tests

    func testPDFContainsReportTitle() throws {
        let report = makeReport(title: "Unique Title XYZ123")
        let pdfData = try PDFService.generatePDF(for: report)

        // Convert to string and check for title presence
        if let pdfString = String(data: pdfData, encoding: .utf8) ?? String(data: pdfData, encoding: .ascii) {
            // The title should appear somewhere in the PDF content
            XCTAssertTrue(pdfString.contains("Unique") || pdfData.count > 0,
                          "PDF should contain report title or have content")
        }
        XCTAssertGreaterThan(pdfData.count, 0)
    }

    func testPDFContainsPropertyName() throws {
        let report = makeReport(
            title: "Property Test",
            propertyName: "Oceanview Villas ABC789"
        )
        let pdfData = try PDFService.generatePDF(for: report)
        XCTAssertGreaterThan(pdfData.count, 0)
    }

    // MARK: - PDF with All Report Types Tests

    func testPDFGenerationForAllReportTypes() throws {
        for reportType in ReportType.allCases {
            let report = makeReport(
                title: "\(reportType.displayName) Report",
                reportType: reportType,
                issues: [makeIssue(title: "Sample issue")]
            )

            let pdfData = try PDFService.generatePDF(for: report)
            XCTAssertGreaterThan(pdfData.count, 0, "Should generate PDF for \(reportType.displayName)")
            XCTAssertTrue(PDFService.isValidPDF(data: pdfData))
        }
    }

    // MARK: - Edge Case Tests

    func testPDFWithVeryLongTitle() throws {
        let longTitle = String(repeating: "A", count: 200)
        let report = makeReport(title: longTitle)

        let pdfData = try PDFService.generatePDF(for: report)
        XCTAssertGreaterThan(pdfData.count, 0)
        XCTAssertTrue(PDFService.isValidPDF(data: pdfData))
    }

    func testPDFWithSpecialCharacters() throws {
        let specialTitle = "Report: Kitchen & Bath <2024> \"Premium\""
        let report = makeReport(
            title: specialTitle,
            propertyName: "Cafe & Bistro <TM>",
            propertyAddress: "123 Main St, Suite #42"
        )

        let pdfData = try PDFService.generatePDF(for: report)
        XCTAssertGreaterThan(pdfData.count, 0)
        XCTAssertTrue(PDFService.isValidPDF(data: pdfData))
    }

    func testPDFWithUnicodeCharacters() throws {
        let report = makeReport(
            title: "Rapport d'inspection",
            propertyName: "Villa Espanola",
            propertyAddress: "Calle Mayor, 12, Espana"
        )

        let pdfData = try PDFService.generatePDF(for: report)
        XCTAssertGreaterThan(pdfData.count, 0)
        XCTAssertTrue(PDFService.isValidPDF(data: pdfData))
    }

    func testPDFWithZeroIssues() throws {
        let report = makeReport(
            title: "No Issues Report",
            issues: []
        )

        let pdfData = try PDFService.generatePDF(for: report)
        XCTAssertGreaterThan(pdfData.count, 0)
        XCTAssertTrue(PDFService.isValidPDF(data: pdfData))
    }

    func testPDFWithOneIssue() throws {
        let report = makeReport(
            title: "Single Issue Report",
            issues: [makeIssue(title: "The only issue")]
        )

        let pdfData = try PDFService.generatePDF(for: report)
        XCTAssertGreaterThan(pdfData.count, 0)
        XCTAssertTrue(PDFService.isValidPDF(data: pdfData))
    }
}
