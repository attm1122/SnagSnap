import SwiftUI

extension View {
    /// Animates this view into place with a fade + slide entry.
    /// Respects Reduce Motion settings.
    func entryAnimation(delay: Double = 0, offsetY: CGFloat = 16) -> some View {
        modifier(EntryAnimationModifier(delay: delay, offsetY: offsetY))
    }

    /// Animates this view with a scale + fade entry.
    /// Respects Reduce Motion settings.
    func scaleEntryAnimation(delay: Double = 0) -> some View {
        modifier(ScaleEntryAnimationModifier(delay: delay))
    }
}

// MARK: - Entry Animation Modifier

struct EntryAnimationModifier: ViewModifier {
    let delay: Double
    let offsetY: CGFloat
    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : offsetY)
            .onAppear {
                let duration = reduceMotion ? 0.01 : 0.4
                withAnimation(.easeOut(duration: duration).delay(delay)) {
                    appeared = true
                }
            }
    }
}

// MARK: - Scale Entry Animation Modifier

struct ScaleEntryAnimationModifier: ViewModifier {
    let delay: Double
    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .scaleEffect(appeared ? 1.0 : 0.85)
            .onAppear {
                let duration = reduceMotion ? 0.01 : 0.35
                withAnimation(.spring(response: duration, dampingFraction: 0.7).delay(delay)) {
                    appeared = true
                }
            }
    }
}

// MARK: - Preview

#Preview("Entry Animations") {
    ScrollView {
        VStack(spacing: Theme.spacingM) {
            ForEach(0..<5) { i in
                Text("Row \(i + 1)")
                    .font(Theme.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Theme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusM))
                    .entryAnimation(delay: Double(i) * 0.05)
            }

            Divider().padding(.vertical)

            ForEach(0..<3) { i in
                Text("Scaled Row \(i + 1)")
                    .font(Theme.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Theme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusM))
                    .scaleEntryAnimation(delay: Double(i) * 0.08)
            }
        }
        .padding()
    }
    .background(Theme.background)
}
