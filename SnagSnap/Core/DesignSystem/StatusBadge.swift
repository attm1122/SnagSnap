import SwiftUI

// MARK: - Report Status Badge

/// A colored pill badge showing a report's status with icon and text.
struct ReportStatusBadge: View {
    let status: ReportStatus

    var body: some View {
        HStack(spacing: Theme.spacingXS) {
            Image(systemName: iconName)
                .font(.caption2)
            Text(status.rawValue)
                .font(Theme.fontCaption.weight(.medium))
        }
        .foregroundStyle(foregroundColor)
        .padding(.horizontal, Theme.spacingS)
        .padding(.vertical, Theme.spacingXS)
        .background(backgroundColor)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(foregroundColor.opacity(0.3), lineWidth: 0.5)
        )
    }

    /// Icon name based on status.
    private var iconName: String {
        switch status {
        case .draft:
            return "doc"
        case .inProgress:
            return "arrow.triangle.2.circlepath"
        case .completed:
            return "checkmark.seal.fill"
        case .archived:
            return "archivebox.fill"
        }
    }

    /// Foreground color based on status.
    private var foregroundColor: Color {
        switch status {
        case .draft:
            return Color.primary
        case .inProgress:
            return .blue
        case .completed:
            return .green
        case .archived:
            return .orange
        }
    }

    /// Background color based on status.
    private var backgroundColor: Color {
        foregroundColor.opacity(0.12)
    }
}

// MARK: - Issue Status Badge

/// A colored pill badge showing an issue's status.
struct IssueStatusBadge: View {
    let status: IssueStatus

    var body: some View {
        HStack(spacing: Theme.spacingXS) {
            Circle()
                .fill(dotColor)
                .frame(width: 6, height: 6)
            Text(status.rawValue)
                .font(Theme.fontCaption.weight(.medium))
        }
        .foregroundStyle(foregroundColor)
        .padding(.horizontal, Theme.spacingS)
        .padding(.vertical, Theme.spacingXS)
        .background(backgroundColor)
        .clipShape(Capsule())
    }

    private var dotColor: Color {
        switch status {
        case .open: return Theme.issueStatusOpen
        case .inProgress: return Theme.issueStatusInProgress
        case .resolved: return Theme.issueStatusResolved
        }
    }

    private var foregroundColor: Color {
        switch status {
        case .open: return .red
        case .inProgress: return .blue
        case .resolved: return .green
        }
    }

    private var backgroundColor: Color {
        foregroundColor.opacity(0.12)
    }
}

// MARK: - Severity Indicator

/// A severity indicator showing a colored dot with optional label.
struct SeverityIndicator: View {
    let severity: IssueSeverity
    var showLabel: Bool = true

    var body: some View {
        HStack(spacing: Theme.spacingXS) {
            Circle()
                .fill(severityColor)
                .frame(width: 8, height: 8)
                .overlay(
                    Circle()
                        .strokeBorder(severityColor.opacity(0.5), lineWidth: 1)
                )

            if showLabel {
                Text(severity.rawValue)
                    .font(Theme.fontCaption.weight(.medium))
                    .foregroundStyle(foregroundColor)
            }
        }
    }

    /// The color for the severity level.
    private var severityColor: Color {
        switch severity {
        case .low:
            return Theme.severityLow
        case .medium:
            return Theme.severityMedium
        case .high:
            return Theme.severityHigh
        case .critical:
            return Theme.severityCritical
        }
    }

    /// The text color for the severity label.
    private var foregroundColor: Color {
        switch severity {
        case .low:
            return Theme.secondaryLabel
        case .medium:
            return .orange
        case .high:
            return .orange
        case .critical:
            return Theme.error
        }
    }
}

// MARK: - Compact Status Dot

/// A minimal status dot for use in list rows.
struct StatusDot: View {
    let color: Color
    var size: CGFloat = 8

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .overlay(
                Circle()
                    .strokeBorder(color.opacity(0.4), lineWidth: 0.5)
            )
    }
}

/// A status dot specifically for issue severity.
struct SeverityDot: View {
    let severity: IssueSeverity
    var size: CGFloat = 8

    var body: some View {
        StatusDot(color: severityColor, size: size)
    }

    private var severityColor: Color {
        switch severity {
        case .low: return Theme.severityLow
        case .medium: return Theme.severityMedium
        case .high: return Theme.severityHigh
        case .critical: return Theme.severityCritical
        }
    }
}

// MARK: - Priority Badge

/// A priority badge with optional icon.
struct PriorityBadge: View {
    let severity: IssueSeverity
    var showIcon: Bool = true

    var body: some View {
        HStack(spacing: Theme.spacingXS) {
            if showIcon {
                Image(systemName: iconName)
                    .font(.caption2)
            }
            Text(severity.rawValue)
                .font(Theme.fontCaption.weight(.semibold))
        }
        .foregroundStyle(foregroundColor)
        .padding(.horizontal, Theme.spacingS)
        .padding(.vertical, Theme.spacingXS)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusSmall))
    }

    private var iconName: String {
        switch severity {
        case .low: return "arrow.down"
        case .medium: return "minus"
        case .high: return "arrow.up"
        case .critical: return "exclamationmark.triangle.fill"
        }
    }

    private var foregroundColor: Color {
        switch severity {
        case .low: return .gray
        case .medium: return .orange
        case .high: return .orange
        case .critical: return Theme.error
        }
    }

    private var backgroundColor: Color {
        foregroundColor.opacity(0.12)
    }
}

// MARK: - Preview Helpers

#Preview {
    ScrollView {
        VStack(spacing: Theme.spacingL) {
            // Report Status Badges
            VStack(alignment: .leading, spacing: Theme.spacingS) {
                Text("Report Status")
                    .font(Theme.fontHeadline)
                HStack {
                    ReportStatusBadge(status: .draft)
                    ReportStatusBadge(status: .inProgress)
                    ReportStatusBadge(status: .completed)
                    ReportStatusBadge(status: .archived)
                }
            }

            Divider()

            // Issue Status Badges
            VStack(alignment: .leading, spacing: Theme.spacingS) {
                Text("Issue Status")
                    .font(Theme.fontHeadline)
                HStack {
                    IssueStatusBadge(status: .open)
                    IssueStatusBadge(status: .inProgress)
                    IssueStatusBadge(status: .resolved)
                }
            }

            Divider()

            // Severity Indicators
            VStack(alignment: .leading, spacing: Theme.spacingS) {
                Text("Severity (with label)")
                    .font(Theme.fontHeadline)
                HStack {
                    SeverityIndicator(severity: .low, showLabel: true)
                    SeverityIndicator(severity: .medium, showLabel: true)
                    SeverityIndicator(severity: .high, showLabel: true)
                    SeverityIndicator(severity: .critical, showLabel: true)
                }
            }

            // Severity Indicators without label
            VStack(alignment: .leading, spacing: Theme.spacingS) {
                Text("Severity (dot only)")
                    .font(Theme.fontHeadline)
                HStack(spacing: Theme.spacingM) {
                    SeverityIndicator(severity: .low, showLabel: false)
                    SeverityIndicator(severity: .medium, showLabel: false)
                    SeverityIndicator(severity: .high, showLabel: false)
                    SeverityIndicator(severity: .critical, showLabel: false)
                }
            }

            Divider()

            // Priority Badges
            VStack(alignment: .leading, spacing: Theme.spacingS) {
                Text("Priority Badges")
                    .font(Theme.fontHeadline)
                HStack {
                    PriorityBadge(severity: .low)
                    PriorityBadge(severity: .medium)
                    PriorityBadge(severity: .high)
                    PriorityBadge(severity: .critical)
                }
            }

            Divider()

            // Severity Dots
            VStack(alignment: .leading, spacing: Theme.spacingS) {
                Text("Severity Dots")
                    .font(Theme.fontHeadline)
                HStack(spacing: Theme.spacingM) {
                    SeverityDot(severity: .low)
                    SeverityDot(severity: .medium)
                    SeverityDot(severity: .high)
                    SeverityDot(severity: .critical)
                }
            }
        }
        .padding(Theme.spacingM)
    }
    .background(Theme.groupedBackground)
}
