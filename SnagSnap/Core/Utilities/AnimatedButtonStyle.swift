import SwiftUI

/// A button style with press animation (scale down) and optional haptic.
struct AnimatedButtonStyle: ButtonStyle {
    let scale: CGFloat
    let haptic: HapticType?

    init(scale: CGFloat = 0.96, haptic: HapticType? = nil) {
        self.scale = scale
        self.haptic = haptic
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .opacity(configuration.isPressed ? 0.92 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { wasPressed, isPressed in
                if !wasPressed && isPressed, let haptic = haptic {
                    HapticService.shared.play(haptic)
                }
            }
    }
}

extension ButtonStyle where Self == AnimatedButtonStyle {
    static func animated(scale: CGFloat = 0.96, haptic: HapticType? = nil) -> AnimatedButtonStyle {
        AnimatedButtonStyle(scale: scale, haptic: haptic)
    }
}

// MARK: - Preview

#Preview("Animated Button Style") {
    VStack(spacing: Theme.spacingM) {
        Button("Default Scale") {}
            .buttonStyle(.animated())

        Button("Light Haptic") {}
            .buttonStyle(.animated(haptic: .light))

        Button("Aggressive Scale + Heavy") {}
            .buttonStyle(.animated(scale: 0.88, haptic: .heavy))
    }
    .padding()
}
