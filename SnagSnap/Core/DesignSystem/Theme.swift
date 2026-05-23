import SwiftUI
import Foundation

// MARK: - Design Tokens
enum Theme {
    // MARK: Primary Colors
    static let primary = Color(red: 0.03, green: 0.42, blue: 0.67)
    static let primaryLight = Color(red: 0.03, green: 0.42, blue: 0.67).opacity(0.12)
    static let accent = Color(red: 0.05, green: 0.58, blue: 0.78)
    static let secondaryAccent = Color(red: 0.20, green: 0.33, blue: 0.63)
    static let ink = Color(red: 0.04, green: 0.06, blue: 0.08)
    static let mutedInk = Color(red: 0.45, green: 0.50, blue: 0.51)
    static let blueSurface = Color(red: 0.91, green: 0.96, blue: 0.98)
    static let blueSurfaceStrong = Color(red: 0.82, green: 0.92, blue: 0.96)

    // MARK: Background Colors
    static let background = Color(red: 0.96, green: 0.98, blue: 0.99)
    static let secondaryBackground = Color.white
    static let groupedBackground = Color(red: 0.96, green: 0.98, blue: 0.99)
    static let secondaryGroupedBackground = Color.white.opacity(0.92)
    static let cardBackground = Color.white
    static let label = ink
    static let secondaryLabel = mutedInk
    static let tertiaryLabel = Color(red: 0.63, green: 0.68, blue: 0.69)
    static let separator = Color(red: 0.82, green: 0.88, blue: 0.91)

    // MARK: Semantic Colors
    static let success = Color(red: 0.20, green: 0.78, blue: 0.35)
    static let info = Color.blue
    static let warning = Color(red: 1.0, green: 0.65, blue: 0.15)
    static let error = Color(red: 0.92, green: 0.26, blue: 0.21)

    // MARK: Report Status Colors (match Enums.swift exactly)
    static let statusDraft = Color.orange
    static let statusReady = Color.blue
    static let statusExported = Color.green
    static let statusArchived = Color.gray

    // MARK: Issue Severity Colors (match Enums.swift exactly)
    static let severityLow = Color.cyan
    static let severityMedium = Color.yellow
    static let severityHigh = Color.orange
    static let severityUrgent = Color.red

    // MARK: Issue Status Colors
    static let issueStatusOpen = Color.red
    static let issueStatusInProgress = Color.blue
    static let issueStatusResolved = Color.green
    static let issueStatusNotAnIssue = Color.gray
    static let issueStatusArchived = Color.gray

    // MARK: Typography (rounded fonts)
    static let fontLargeTitle = Font.system(.largeTitle, design: .default, weight: .bold)
    static let fontTitle = Font.system(.title, design: .default, weight: .bold)
    static let fontTitle2 = Font.system(.title2, design: .default, weight: .semibold)
    static let fontTitle3 = Font.system(.title3, design: .default, weight: .semibold)
    static let fontHeadline = Font.system(.headline, design: .default, weight: .semibold)
    static let fontSubheadline = Font.system(.subheadline, design: .default, weight: .regular)
    static let fontBody = Font.system(.body, design: .default, weight: .regular)
    static let fontCallout = Font.system(.callout, design: .default, weight: .medium)
    static let fontFootnote = Font.system(.footnote, design: .default, weight: .regular)
    static let fontCaption = Font.system(.caption, design: .default, weight: .medium)

    // MARK: Typography Convenience Shorthands
    static let largeTitle = fontLargeTitle
    static let title = fontTitle
    static let title2 = fontTitle2
    static let title3 = fontTitle3
    static let headline = fontHeadline
    static let subheadline = fontSubheadline
    static let body = fontBody
    static let callout = fontCallout
    static let footnote = fontFootnote
    static let caption = fontCaption

    // MARK: Body Medium (medium weight body for buttons)
    static let bodyMedium = Font.system(.body, design: .default, weight: .medium)

    // MARK: Icon Sizes
    static let iconSizeS: CGFloat = 12
    static let iconSizeM: CGFloat = 16
    static let iconSizeL: CGFloat = 24
    static let iconSizeXL: CGFloat = 32

    // MARK: Button Height
    static let buttonHeight: CGFloat = 48

    // MARK: Corner Radius Convenience Shorthands
    static let cornerRadiusS: CGFloat = radiusSmall
    static let cornerRadiusM: CGFloat = radiusMedium
    static let cornerRadiusL: CGFloat = radiusLarge
    static let cornerRadiusXL: CGFloat = radiusXL

    // MARK: Spacing
    static let spacingXS: CGFloat = 4
    static let spacingS: CGFloat = 8
    static let spacingM: CGFloat = 16
    static let spacingL: CGFloat = 24
    static let spacingXL: CGFloat = 32
    static let spacingXXL: CGFloat = 48

    // MARK: Corner Radius
    static let radiusSmall: CGFloat = 6
    static let radiusMedium: CGFloat = 12
    static let radiusLarge: CGFloat = 20
    static let radiusXL: CGFloat = 28

    // MARK: Shadows
    static let shadowColor = Color(red: 0.03, green: 0.20, blue: 0.31).opacity(0.08)
    static let shadowRadiusSmall: CGFloat = 0
    static let shadowRadiusMedium: CGFloat = 6
    static let shadowRadiusLarge: CGFloat = 18
    static let shadowYOffsetSmall: CGFloat = 0
    static let shadowYOffsetMedium: CGFloat = 8
    static let shadowRadius: CGFloat = shadowRadiusMedium
    static let shadowY: CGFloat = shadowYOffsetSmall
    static let tertiaryBackground = Color(.tertiarySystemGroupedBackground)

    // MARK: Icons (SF Symbols)
    static let iconHome = "house.fill"
    static let iconSettings = "gearshape.fill"
    static let iconReports = "doc.text.fill"
    static let iconAdd = "plus"
    static let iconCamera = "camera.fill"
    static let iconPhoto = "photo.fill"
    static let iconCheckmark = "checkmark.circle.fill"
    static let iconChevronRight = "chevron.right"
    static let iconTrash = "trash.fill"
    static let iconEdit = "pencil"
    static let iconPDF = "doc.fill"
    static let iconShare = "square.and.arrow.up"
    static let iconArea = "square.grid.2x2"
    static let iconIssue = "exclamationmark.triangle.fill"
    static let iconBack = "chevron.left"
    static let iconClose = "xmark"
    static let iconSearch = "magnifyingglass"
    static let iconFilter = "line.3.horizontal.decrease"
    static let iconSort = "arrow.up.arrow.down"
    static let iconMore = "ellipsis"
    static let iconStar = "star.fill"
    static let iconLock = "lock.fill"
    static let iconUnlock = "lock.open.fill"
    static let iconPerson = "person.fill"
    static let iconCalendar = "calendar"
    static let iconClock = "clock"
    static let iconLocation = "mappin.and.ellipse"
    static let iconNote = "note.text"
    static let iconPin = "pin.fill"
    static let iconCircle = "circle.fill"
    static let iconArrowUp = "arrow.up"
    static let iconArrowDown = "arrow.down"
}
