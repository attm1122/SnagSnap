// SnagSnap
// OverviewTabView.swift
//
// Overview tab showing report details, stats grid, severity breakdown,
// and export action for the report workspace.

import SwiftUI
import SwiftData

// MARK: - OverviewTabView

/// Displays a high-level summary of the inspection report including
/// property details, issue statistics, severity breakdown, and export action.
struct OverviewTabView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme

    let report: InspectionReport
    let viewModel: ReportWorkspaceViewModel

    // MARK: - Body

    var body: some View {
        VStack(spacing: Theme.spacingL) {
            // Report details card
            reportDetailsCard

            // Property details card
            propertyDetailsCard

            // Stats grid
            statsGrid

            // Severity breakdown bar
            if (report.issues?.count ?? 0) > 0 {
                severityBreakdownSection
            }

            // Export button
            exportButton
        }
        .padding(Theme.spacingM)
    }

    // MARK: - Report Details Card

    private var reportDetailsCard: some View {
        SSCard(padding: Theme.spacingL, cornerRadius: Theme.radiusLarge) {
            VStack(alignment: .leading, spacing: Theme.spacingM) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: Theme.spacingS) {
                        Text(report.title)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.primary)
                            .lineLimit(2)

                        Text(report.propertyName)
                            .font(.headline)
                            .foregroundStyle(.secondary)

                        Text(report.propertyAddress)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }

                    Spacer()

                    ReportStatusBadge(status: report.status)
                }

                Divider()

                HStack(spacing: Theme.spacingXL) {
                    detailItem(icon: report.reportType.icon, label: "Type", value: report.reportType.displayName)
                    detailItem(icon: "calendar", label: "Date", value: report.displayDate)
                }
            }
        }
    }

    // MARK: - Property Details Card

    private var propertyDetailsCard: some View {
        SSCard(padding: Theme.spacingL, cornerRadius: Theme.radiusLarge) {
            VStack(alignment: .leading, spacing: Theme.spacingM) {
                SSSectionHeader("Property Details")

                VStack(alignment: .leading, spacing: Theme.spacingS) {
                    if let clientName = report.clientName, !clientName.isEmpty {
                        propertyDetailRow(icon: "person.fill", label: "Client", value: clientName)
                    }

                    if let inspectorName = report.inspectorName, !inspectorName.isEmpty {
                        propertyDetailRow(icon: "checkmark.shield.fill", label: "Inspector", value: inspectorName)
                    }

                    if let notes = report.generalNotes, !notes.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: Theme.spacingS) {
                                Image(systemName: "note.text")
                                    .foregroundStyle(Theme.primary)
                                    .frame(width: 20)
                                Text("Notes")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.secondary)
                            }
                            Text(notes)
                                .font(.body)
                                .foregroundStyle(.primary)
                                .padding(.leading, 28)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Theme.spacingM) {
            statCard(
                icon: "square.grid.2x2",
                iconColor: .blue,
                value: "\(report.areaCount)",
                label: "Areas"
            )

            statCard(
                icon: "exclamationmark.triangle.fill",
                iconColor: .orange,
                value: "\(report.issueCount)",
                label: "Total Issues"
            )

            statCard(
                icon: "circle.fill",
                iconColor: .red,
                value: "\(report.openIssueCount)",
                label: "Open Issues"
            )

            statCard(
                icon: "checkmark.circle.fill",
                iconColor: .green,
                value: "\(report.fixedIssueCount)",
                label: "Fixed Issues"
            )
        }
    }

    // MARK: - Severity Breakdown Section

    private var severityBreakdownSection: some View {
        SSCard(padding: Theme.spacingL, cornerRadius: Theme.radiusLarge) {
            VStack(alignment: .leading, spacing: Theme.spacingM) {
                SSSectionHeader("Severity Breakdown")

                // Segmented bar
                severityBar

                // Legend
                severityLegend
            }
        }
    }

    private var severityBar: some View {
        let breakdown = viewModel.severityBreakdown(for: report)
        let total = report.issueCount

        return GeometryReader { geometry in
            HStack(spacing: 0) {
                ForEach(breakdown, id: \.severity) { item in
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(item.severity.color)
                        .frame(width: geometry.size.width * CGFloat(item.percentage))
                }
            }
            .frame(height: 12)
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        }
        .frame(height: 12)
        .overlay(
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
        )
    }

    private var severityLegend: some View {
        let breakdown = viewModel.severityBreakdown(for: report)

        return VStack(alignment: .leading, spacing: Theme.spacingS) {
            ForEach(breakdown, id: \.severity) { item in
                HStack(spacing: Theme.spacingS) {
                    Circle()
                        .fill(item.severity.color)
                        .frame(width: 10, height: 10)

                    Text(item.severity.displayName)
                        .font(.subheadline)
                        .foregroundStyle(.primary)

                    Spacer()

                    Text("\(item.count)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text("(\(Int(item.percentage * 100))%)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 40, alignment: .trailing)
                }
            }
        }
    }

    // MARK: - Export Button

    private var exportButton: some View {
        SSButton(
            "Export Report",
            style: .primary,
            icon: "square.and.arrow.up",
            isFullWidth: true
        ) {
            viewModel.generatePDF(for: report)
        }
        .padding(.top, Theme.spacingS)
    }

    // MARK: - Helper Views

    private func detailItem(icon: String, label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(Theme.primary)
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
        }
    }

    private func propertyDetailRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: Theme.spacingS) {
            Image(systemName: icon)
                .foregroundStyle(Theme.primary)
                .frame(width: 20)
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
        }
    }

    private func statCard(icon: String, iconColor: Color, value: String, label: String) -> some View {
        SSCard(padding: Theme.spacingM, cornerRadius: Theme.radiusMedium) {
            VStack(alignment: .leading, spacing: Theme.spacingS) {
                HStack {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(iconColor)

                    Spacer()
                }

                Text(value)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.primary)

                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Preview

#Preview("Overview Tab") {
    let schema = Schema([InspectionReport.self, InspectionArea.self, InspectionIssue.self, IssuePhoto.self])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [config])
    let context = ModelContext(container)

    let report = InspectionReport(
        title: "15 Oak Avenue - Move In",
        propertyName: "15 Oak Avenue",
        propertyAddress: "15 Oak Avenue, Manchester M1 1AA",
        reportType: .moveIn,
        clientName: "Sarah Johnson",
        inspectorName: "Mike Thompson",
        generalNotes: "Standard move-in inspection. Tenant present during inspection."
    )
    context.insert(report)

    let kitchen = InspectionArea(name: "Kitchen", notes: "Modern fitted kitchen")
    context.insert(kitchen)
    kitchen.report = report
    report.areas = [kitchen]

    let bathroom = InspectionArea(name: "Bathroom", notes: "Family bathroom with shower over bath")
    context.insert(bathroom)
    bathroom.report = report
    report.areas?.append(bathroom)

    let issue1 = InspectionIssue(title: "Cracked tile near sink", notes: "Visible crack in ceramic tile", severity: .high, status: .open)
    context.insert(issue1)
    issue1.report = report
    issue1.area = kitchen

    let issue2 = InspectionIssue(title: "Loose door handle", severity: .low, status: .fixed)
    context.insert(issue2)
    issue2.report = report
    issue2.area = bathroom

    let issue3 = InspectionIssue(title: "Water stain on ceiling", notes: "Discoloration indicating possible leak", severity: .urgent, status: .open)
    context.insert(issue3)
    issue3.report = report
    issue3.area = kitchen

    let issue4 = InspectionIssue(title: "Scuffed paintwork", severity: .medium, status: .inProgress)
    context.insert(issue4)
    issue4.report = report
    issue4.area = kitchen

    report.issues = [issue1, issue2, issue3, issue4]
    try? context.save()

    let vm = ReportWorkspaceViewModel()

    return ScrollView {
        OverviewTabView(report: report, viewModel: vm)
            .padding(Theme.spacingM)
    }
    .background(Theme.groupedBackground)
    .modelContainer(container)
}
