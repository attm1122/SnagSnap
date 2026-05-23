import SwiftUI

// MARK: - SSLoadingView

/// A full-screen loading overlay with a spinner and an optional message.
/// Covers the entire screen with a semi-transparent backdrop.
struct SSLoadingView: View {
    let message: String?

    // MARK: - Initializer

    /// Creates a new ``SSLoadingView``.
    /// - Parameter message: Optional descriptive text shown beneath the spinner.
    init(message: String? = nil) {
        self.message = message
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Semi-transparent backdrop
            Color.black
                .opacity(0.28)
                .ignoresSafeArea()

            // Card container
            VStack(spacing: Theme.spacingM) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Theme.primary))
                    .scaleEffect(1.4)
                    .padding(.top, Theme.spacingS)

                if let message = message {
                    Text(message)
                        .font(Theme.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Theme.spacingM)
                        .padding(.bottom, Theme.spacingS)
                }
            }
            .padding(Theme.spacingXL)
            .background(
                Theme.cardBackground
                    .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusL, style: .continuous))
            )
            .shadow(
                color: Color.black.opacity(0.15),
                radius: 20,
                x: 0,
                y: 8
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message ?? "Loading")
    }
}

// MARK: - View Modifier

extension View {
    /// Conditionally overlays an ``SSLoadingView`` on top of the receiver.
    /// - Parameters:
    ///   - isPresented: Whether the loading overlay is visible.
    ///   - message: Optional message shown beneath the spinner.
    func loadingOverlay(isPresented: Bool, message: String? = nil) -> some View {
        self.overlay {
            if isPresented {
                SSLoadingView(message: message)
                    .transition(.opacity.animation(.easeInOut(duration: 0.2)))
            }
        }
    }
}

// MARK: - Preview

#Preview("SSLoadingView") {
    ZStack {
        Theme.background.ignoresSafeArea()

        VStack {
            Text("Content behind the loading view")
                .font(Theme.body)
            Spacer()
        }
        .padding()

        SSLoadingView(message: "Saving report…")
    }
}
