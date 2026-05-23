import Foundation
import SwiftData

enum CaptureDraftFactory {
    static func makeCaptureDraft(context: ModelContext) throws -> (report: InspectionReport, area: InspectionArea) {
        let report = InspectionReport(
            title: "Draft Photo Report",
            propertyName: "Property to identify",
            propertyAddress: "Address to add",
            reportType: .general,
            generalNotes: "Started from photo capture. Complete the property details before sharing."
        )
        let area = InspectionArea(name: "General")

        context.insert(report)
        context.insert(area)
        area.report = report
        report.areas = [area]
        report.updatedAt = Date()

        try context.save()
        return (report, area)
    }

    static func generalArea(for report: InspectionReport, context: ModelContext) throws -> InspectionArea {
        if let existingArea = report.areas?.first {
            return existingArea
        }

        let area = InspectionArea(name: "General")
        context.insert(area)
        area.report = report

        if report.areas == nil {
            report.areas = []
        }
        report.areas?.append(area)
        report.updatedAt = Date()

        try context.save()
        return area
    }
}
