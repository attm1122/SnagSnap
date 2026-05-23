// SnagSnap
// AreasTabView.swift
//
// Areas tab for the report workspace. Lists all inspection areas
// with issue counts, supports add, edit, and delete operations.

import SwiftUI
import SwiftData

// MARK: - AreasTabView

/// Displays all inspection areas within a report, supporting CRUD operations.
struct AreasTabView: View {

    @Environment(\.modelContext) private var modelContext

    let report: InspectionReport
    @Bindable var viewModel: ReportWorkspaceViewModel

    // MARK: - Local State

    @State private var selectedArea: InspectionArea? = nil
    @State private var showEditSheet = false

    // MARK: - Body

    var body: some View {
        VStack(spacing: Theme.spacingL) {
            // Add area button
            addAreaButton

            // Areas list
            if let areas = report.areas, !areas.isEmpty {
                areasList(areas: areas)
            } else {
                emptyState
            }
        }
        .padding(Theme.spacingM)
        .sheet(isPresented: $viewModel.showAddAreaSheet) {
            AddEditAreaView(report: report)
        }
        .sheet(isPresented: $showEditSheet) {
            if let area = selectedArea {
                AddEditAreaView(area: area, report: report)
            }
        }
        .animateOnAppear(delay: 0.05, duration: 0.4)
    }

    // MARK: - Add Area Button

    private var addAreaButton: some View {
        SSButton(
            "Add Area",
            style: .secondary,
            icon: "plus",
            isFullWidth: true
        ) {
            viewModel.showAddAreaSheet = true
        }
        .buttonStyle(.animated(haptic: .medium))
    }

    // MARK: - Areas List

    private func areasList(areas: [InspectionArea]) -> some View {
        LazyVStack(spacing: Theme.spacingM) {
            ForEach(areas) { area in
                AreaRow(area: area)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        HapticService.shared.play(.light)
                        selectedArea = area
                        showEditSheet = true
                    }
                    .transition(
                        .asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .opacity
                        )
                    )
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            HapticService.shared.play(.medium)
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                deleteArea(area)
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .contextMenu {
                        Button {
                            selectedArea = area
                            showEditSheet = true
                        } label: {
                            Label("Edit Area", systemImage: "pencil")
                        }

                        Button(role: .destructive) {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                deleteArea(area)
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        SSEmptyState(
            icon: "square.grid.2x2",
            title: "No Areas Yet",
            message: "Add areas to your report to organize issues by room or zone.",
            buttonTitle: "Add Area",
            buttonAction: {
                viewModel.showAddAreaSheet = true
            }
        )
        .scaleEntryAnimation(delay: 0.1)
        .padding(.top, Theme.spacingXXL)
    }

    // MARK: - Actions

    private func deleteArea(_ area: InspectionArea) {
        HapticService.shared.play(.medium)
        if let issues = area.issues {
            for issue in issues {
                report.issues?.removeAll { $0.id == issue.id }
            }
        }
        report.areas?.removeAll { $0.id == area.id }
        report.updatedAt = Date()
        modelContext.delete(area)
        try? modelContext.save()
    }
}

// MARK: - Area Row

private struct AreaRow: View {
    let area: InspectionArea
    @State private var isVisible = false

    var body: some View {
        SSCard(padding: Theme.spacingM, cornerRadius: Theme.radiusMedium) {
            HStack(spacing: Theme.spacingM) {
                // Area icon
                ZStack {
                    RoundedRectangle(cornerRadius: Theme.radiusMedium, style: .continuous)
                        .fill(Theme.primary.opacity(0.1))
                        .frame(width: 48, height: 48)

                    Image(systemName: "square.grid.2x2")
                        .font(.title3)
                        .foregroundStyle(Theme.primary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(area.name)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary)

                    if let notes = area.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    HStack(spacing: Theme.spacingS) {
                        issueCountBadge(count: area.issueCount)
                        photoCountBadge(count: area.photoCount)
                    }
                    .padding(.top, 2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 8)
        .scaleEffect(isVisible ? 1.0 : 0.96)
        .animation(.easeOut(duration: 0.35).delay(0.05), value: isVisible)
        .onAppear {
            isVisible = true
        }
        .onDisappear {
            isVisible = false
        }
    }

    private func issueCountBadge(count: Int) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.caption2)
            Text("\(count)")
                .font(.caption.weight(.medium))
                .contentTransition(.numericText())
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: count)
        }
        .foregroundStyle(count > 0 ? Theme.warning : .secondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            (count > 0 ? Theme.warning : Color.gray).opacity(0.1)
        )
        .clipShape(Capsule())
    }

    private func photoCountBadge(count: Int) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "photo.fill")
                .font(.caption2)
            Text("\(count)")
                .font(.caption.weight(.medium))
                .contentTransition(.numericText())
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: count)
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.gray.opacity(0.1))
        .clipShape(Capsule())
    }
}

// MARK: - Preview

#Preview("Areas Tab") {
    let schema = Schema([InspectionReport.self, InspectionArea.self, InspectionIssue.self, IssuePhoto.self])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [config])
    let context = ModelContext(container)

    let report = InspectionReport(
        title: "Sample Report",
        propertyName: "15 Oak Avenue",
        propertyAddress: "15 Oak Avenue, Manchester M1 1AA",
        reportType: .moveIn
    )
    context.insert(report)

    let kitchen = InspectionArea(name: "Kitchen", notes: "Modern fitted kitchen with granite worktops")
    context.insert(kitchen)
    kitchen.report = report

    let bathroom = InspectionArea(name: "Bathroom", notes: "Family bathroom")
    context.insert(bathroom)
    bathroom.report = report

    let bedroom = InspectionArea(name: "Master Bedroom", notes: "Large double bedroom with en-suite")
    context.insert(bedroom)
    bedroom.report = report

    report.areas = [kitchen, bathroom, bedroom]

    let issue1 = InspectionIssue(title: "Cracked tile", severity: .high, status: .open)
    context.insert(issue1)
    issue1.report = report
    issue1.area = kitchen

    let issue2 = InspectionIssue(title: "Loose handle", severity: .low, status: .open)
    context.insert(issue2)
    issue2.report = report
    issue2.area = kitchen

    kitchen.issues = [issue1, issue2]
    report.issues = [issue1, issue2]
    try? context.save()

    let vm = ReportWorkspaceViewModel()

    return ScrollView {
        AreasTabView(report: report, viewModel: vm)
            .padding(Theme.spacingM)
    }
    .background(Theme.groupedBackground)
    .modelContainer(container)
}
