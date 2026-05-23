import SwiftUI
import Foundation

// MARK: - Design Tokens
enum Theme {
    // MARK: Colors
    static let primary = Color.accentColor
    static let primaryLight = Color.accentColor.opacity(0.15)
    static let background = Color(.systemBackground)
    static let secondaryBackground = Color(.secondarySystemBackground)
    static let groupedBackground = Color(.systemGroupedBackground)
    static let secondaryGroupedBackground = Color(.secondarySystemGroupedBackground)
    static let label = Color(.label)
    static let secondaryLabel = Color(.secondaryLabel)
    static let tertiaryLabel = Color(.tertiaryLabel)
    static let separator = Color(.separator)
    static let error = Color(.systemRed)
    static let success = Color(.systemGreen)
    static let warning = Color(.systemOrange)

    // MARK: Status Colors
    static let statusDraft = Color.gray
    static let statusInProgress = Color.blue
    static let statusCompleted = Color.green
    static let statusArchived = Color.orange

    // MARK: Severity Colors
    static let severityLow = Color.gray
    static let severityMedium = Color.yellow
    static let severityHigh = Color.orange
    static let severityCritical = Color.red

    // MARK: Issue Status Colors
    static let issueStatusOpen = Color.red
    static let issueStatusInProgress = Color.blue
    static let issueStatusResolved = Color.green

    // MARK: Typography
    static let fontLargeTitle = Font.largeTitle.weight(.bold)
    static let fontTitle = Font.title.weight(.semibold)
    static let fontTitle2 = Font.title2.weight(.semibold)
    static let fontTitle3 = Font.title3.weight(.semibold)
    static let fontHeadline = Font.headline
    static let fontSubheadline = Font.subheadline
    static let fontBody = Font.body
    static let fontCallout = Font.callout
    static let fontFootnote = Font.footnote
    static let fontCaption = Font.caption

    // MARK: Spacing
    static let spacingXS: CGFloat = 4
    static let spacingS: CGFloat = 8
    static let spacingM: CGFloat = 16
    static let spacingL: CGFloat = 24
    static let spacingXL: CGFloat = 32
    static let spacingXXL: CGFloat = 48

    // MARK: Corner Radius
    static let radiusSmall: CGFloat = 6
    static let radiusMedium: CGFloat = 10
    static let radiusLarge: CGFloat = 16
    static let radiusXL: CGFloat = 24

    // MARK: Shadows
    static let shadowColor = Color.black.opacity(0.1)
    static let shadowRadiusSmall: CGFloat = 4
    static let shadowRadiusMedium: CGFloat = 8
    static let shadowRadiusLarge: CGFloat = 16
    static let shadowYOffsetSmall: CGFloat = 2
    static let shadowYOffsetMedium: CGFloat = 4

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
