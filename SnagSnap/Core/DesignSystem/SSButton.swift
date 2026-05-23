import SwiftUI

// MARK: - Button Style Enum

/// Defines the visual style of an ``SSButton``.
enum SSButtonStyle {
    case primary
    case secondary
    case tertiary
    case fab
    case destructive
}

// MARK: - SSButton

/// A reusable, theme-aware button supporting multiple styles, loading state,
/// disabled state, and an optional full-width layout.
struct SSButton: View {
    let title: String
    let style: SSButtonStyle
    let icon: String?
    let isLoading: Bool
    let isDisabled: Bool
    let isFullWidth: Bool
    let action: () -> Void

    // MARK: - Initializer

    /// Creates a new ``SSButton``.
    /// - Parameters:
    ///   - title: The button label text.
    ///   - style: Visual style (default `.primary`).
    ///   - icon: Optional SF Symbol name displayed beside the title.
    ///   - isLoading: Whether to show a progress spinner instead of the label.
    ///   - isDisabled: Whether interaction is disabled.
    ///   - isFullWidth: Whether the button expands to fill its parent width.
    ///   - action: Closure invoked on tap.
    init(
        _ title: String,
        style: SSButtonStyle = .primary,
        icon: String? = nil,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        isFullWidth: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.icon = icon
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.isFullWidth = isFullWidth
        self.action = action
    }

    init(
        title: String,
        style: SSButtonStyle = .primary,
        icon: String? = nil,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        isFullWidth: Bool = false,
        action: @escaping () -> Void
    ) {
        self.init(
            title,
            style: style,
            icon: icon,
            isLoading: isLoading,
            isDisabled: isDisabled,
            isFullWidth: isFullWidth,
            action: action
        )
    }

    // MARK: - Body

    var body: some View {
        Button(action: handleTap) {
            ZStack {
                // Loading spinner
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: foregroundColor))
                        .scaleEffect(1.1)
                }

                // Label (hidden while loading)
                HStack(spacing: Theme.spacingS) {
                    if let icon = icon, style != .fab {
                        Image(systemName: icon)
                            .font(.system(size: Theme.iconSizeM, weight: .semibold))
                    }

                    if style != .fab {
                        Text(title)
                            .font(Theme.bodyMedium)
                    } else {
                        Image(systemName: icon ?? "plus")
                            .font(.system(size: Theme.iconSizeXL, weight: .semibold))
                    }
                }
                .opacity(isLoading ? 0 : 1)
            }
            .frame(maxWidth: isFullWidth && style != .fab ? .infinity : nil)
            .frame(height: style == .fab ? fabSize : Theme.buttonHeight)
            .if(isFullWidth && style != .fab) { view in
                view.frame(maxWidth: .infinity)
            }
            .padding(.horizontal, horizontalPadding)
            .background(backgroundView)
            .foregroundStyle(foregroundColor)
            .clipShape(clipShape)
            .overlay(borderOverlay)
            .opacity(isDisabled || isLoading ? 0.6 : 1.0)
        }
        .disabled(isDisabled || isLoading)
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabelText)
    }

    private var accessibilityLabelText: String {
        if isLoading { return "Loading \(title)" }
        return title
    }

    // MARK: - Actions

    private func handleTap() {
        guard !isDisabled, !isLoading else { return }
        HapticService.shared.play(.light)
        action()
    }

    // MARK: - Layout Constants

    private var fabSize: CGFloat { 56 }

    private var horizontalPadding: CGFloat {
        switch style {
        case .fab: return 0
        case .tertiary: return Theme.spacingS
        default: return Theme.spacingM
        }
    }

    private var clipShape: some Shape {
        RoundedRectangle(
            cornerRadius: style == .fab ? fabSize / 2 : Theme.cornerRadiusM,
            style: .continuous
        )
    }

    // MARK: - Colors

    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .primary:
            Theme.primary
        case .secondary:
            Theme.blueSurface
        case .tertiary:
            Color.clear
        case .fab:
            Theme.ink
        case .destructive:
            Theme.error
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary, .fab, .destructive:
            .white
        case .secondary:
            Theme.primary
        case .tertiary:
            Theme.primary
        }
    }

    @ViewBuilder
    private var borderOverlay: some View {
        switch style {
        case .secondary:
            RoundedRectangle(cornerRadius: Theme.cornerRadiusM, style: .continuous)
                .stroke(Theme.primary.opacity(0.18), lineWidth: 1)
        default:
            EmptyView()
        }
    }
}

// MARK: - Preview

#Preview("SSButton Styles") {
    ScrollView {
        VStack(spacing: Theme.spacingM) {
            SSButton("Primary Button", style: .primary, isFullWidth: true) {}
            SSButton("Primary with Icon", style: .primary, icon: "arrow.right", isFullWidth: true) {}
            SSButton("Secondary Button", style: .secondary, isFullWidth: true) {}
            SSButton("Tertiary Button", style: .tertiary) {}
            SSButton("Destructive", style: .destructive, isFullWidth: true) {}
            SSButton("Loading State", style: .primary, isLoading: true, isFullWidth: true) {}
            SSButton("Disabled", style: .primary, isDisabled: true, isFullWidth: true) {}

            HStack {
                Spacer()
                SSButton("", style: .fab, icon: "plus") {}
                Spacer()
            }
        }
        .padding(Theme.spacingM)
    }
    .background(Theme.background)
}
