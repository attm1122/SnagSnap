import SwiftUI

// MARK: - Card Style

extension View {
    /// Apply the app's card style with background, corner radius, and shadow.
    ///
    /// - Parameter padding: Internal padding for the card content.
    func cardStyle(padding: CGFloat = Theme.spacingM) -> some View {
        self
            .padding(padding)
            .background(Theme.secondaryGroupedBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMedium, style: .continuous))
            .shadow(
                color: Theme.shadowColor,
                radius: Theme.shadowRadiusSmall,
                x: 0,
                y: Theme.shadowYOffsetSmall
            )
    }

    /// Apply card style with custom background color.
    func cardStyle(
        padding: CGFloat = Theme.spacingM,
        background: Color = Theme.secondaryGroupedBackground
    ) -> some View {
        self
            .padding(padding)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMedium, style: .continuous))
            .shadow(
                color: Theme.shadowColor,
                radius: Theme.shadowRadiusSmall,
                x: 0,
                y: Theme.shadowYOffsetSmall
            )
    }
}

// MARK: - Keyboard

extension View {
    /// Dismiss the keyboard programmatically.
    func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }

    /// Hide keyboard when the user scrolls.
    func dismissKeyboardOnScroll() -> some View {
        self.onAppear {
            UIScrollView.appearance().keyboardDismissMode = .onDrag
        }
    }
}

// MARK: - Conditional Modifier

extension View {
    /// Conditionally apply a transformation to the view.
    ///
    /// - Parameters:
    ///   - condition: Whether to apply the transformation.
    ///   - transform: The transformation to apply.
    /// - Returns: The original or transformed view.
    @ViewBuilder
    func `if`<Transform: View>(
        _ condition: Bool,
        transform: (Self) -> Transform
    ) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    /// Conditionally apply one of two transformations.
    ///
    /// - Parameters:
    ///   - condition: Which transformation to apply.
    ///   - trueTransform: Transformation applied when condition is true.
    ///   - falseTransform: Transformation applied when condition is false.
    @ViewBuilder
    func `if`<TrueContent: View, FalseContent: View>(
        _ condition: Bool,
        true trueTransform: (Self) -> TrueContent,
        false falseTransform: (Self) -> FalseContent
    ) -> some View {
        if condition {
            trueTransform(self)
        } else {
            falseTransform(self)
        }
    }
}

// MARK: - Optional Modifier

extension View {
    /// Apply a transformation if an optional value is present.
    ///
    /// - Parameters:
    ///   - value: The optional value to check.
    ///   - transform: The transformation to apply with the unwrapped value.
    @ViewBuilder
    func ifLet<T, Transform: View>(
        _ value: T?,
        transform: (Self, T) -> Transform
    ) -> some View {
        if let value {
            transform(self, value)
        } else {
            self
        }
    }
}

// MARK: - Read Size

extension View {
    /// Read the size of the view and pass it to a closure.
    func readSize(onChange: @escaping (CGSize) -> Void) -> some View {
        background(
            GeometryReader { geometryProxy in
                Color.clear
                    .preference(key: SizePreferenceKey.self, value: geometryProxy.size)
            }
        )
        .onPreferenceChange(SizePreferenceKey.self, perform: onChange)
    }

    /// Read the frame of the view in a given coordinate space.
    func readFrame(
        in coordinateSpace: CoordinateSpace = .global,
        onChange: @escaping (CGRect) -> Void
    ) -> some View {
        background(
            GeometryReader { geometryProxy in
                Color.clear
                    .preference(key: FramePreferenceKey.self, value: geometryProxy.frame(in: coordinateSpace))
            }
        )
        .onPreferenceChange(FramePreferenceKey.self, perform: onChange)
    }
}

// MARK: - Preference Keys

struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

struct FramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

// MARK: - Placeholder / Skeleton Loading

extension View {
    /// Show a placeholder while content is loading.
    func skeleton(isLoading: Bool) -> some View {
        self
            .redacted(reason: isLoading ? .placeholder : [])
            .shimmering(active: isLoading)
    }

    /// Apply a shimmer effect.
    func shimmering(active: Bool = true) -> some View {
        self.overlay(
            GeometryReader { geometry in
                if active {
                    ShimmerView()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipShape(Rectangle())
                }
            }
        )
    }
}

// MARK: - Shimmer Effect View

struct ShimmerView: View {
    @State private var phase: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color.white.opacity(0.3), location: 0.0),
                    .init(color: Color.white.opacity(0.6), location: 0.5),
                    .init(color: Color.white.opacity(0.3), location: 1.0)
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: geometry.size.width * 2)
            .offset(x: -geometry.size.width + phase * geometry.size.width * 2)
        }
        .animation(
            .linear(duration: 1.5).repeatForever(autoreverses: false),
            value: phase
        )
        .onAppear {
            phase = 1
        }
    }
}

// MARK: - Tap Feedback

extension View {
    /// Add a scale animation on tap.
    func scaleOnTap(scale: CGFloat = 0.96) -> some View {
        self.buttonStyle(ScaleButtonStyle(scale: scale))
    }

    /// Add an opacity change on tap.
    func opacityOnTap(opacity: Double = 0.7) -> some View {
        self.buttonStyle(OpacityButtonStyle(opacity: opacity))
    }
}

struct ScaleButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.96

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct OpacityButtonStyle: ButtonStyle {
    var opacity: Double = 0.7

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? opacity : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Navigation

extension View {
    /// Configure a navigation bar with a title and optional display mode.
    func withNavigationBar(
        title: String,
        displayMode: NavigationBarItem.TitleDisplayMode = .inline
    ) -> some View {
        self.navigationTitle(title)
            .navigationBarTitleDisplayMode(displayMode)
    }

    /// Add a toolbar back button with custom action.
    func withBackButton(action: @escaping () -> Void) -> some View {
        self.toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: action) {
                    HStack(spacing: Theme.spacingXS) {
                        Image(systemName: Theme.iconBack)
                        Text("Back")
                    }
                }
            }
        }
    }

    /// Add a toolbar close button.
    func withCloseButton(action: @escaping () -> Void) -> some View {
        self.toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: action) {
                    Image(systemName: Theme.iconClose)
                }
            }
        }
    }
}

// MARK: - Safe Area

extension View {
    /// Ignore the keyboard safe area.
    func ignoreKeyboard() -> some View {
        self.ignoresSafeArea(.keyboard)
    }
}

// MARK: - Accessibility

extension View {
    /// Apply accessibility traits to the view.
    func accessibility(
        label: String,
        hint: String? = nil,
        traits: AccessibilityTraits = []
    ) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(traits)
    }
}
