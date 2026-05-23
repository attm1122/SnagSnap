// SnagSnap
// SSToast.swift
//
// A simple toast view that appears and fades for user feedback.

import SwiftUI

// MARK: - Toast Style

extension SSToast {
    enum ToastStyle {
        case success, error, info

        var color: Color {
            switch self {
            case .success: return Theme.success
            case .error: return Theme.error
            case .info: return Theme.primary
            }
        }

        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .error: return "exclamationmark.circle.fill"
            case .info: return "info.circle.fill"
            }
        }
    }
}

// MARK: - SSToast View

/// A toast view displaying a message with an icon and background color.
struct SSToast: View {
    let message: String
    let icon: String
    let style: ToastStyle

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(.white)
            Text(message)
                .font(Theme.fontCallout)
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(style.color)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Toast Modifier

/// A view modifier that presents a toast at the bottom of the screen.
struct ToastModifier: ViewModifier {
    @Binding var isPresented: Bool
    let message: String
    let style: SSToast.ToastStyle
    let duration: Double

    @State private var workItem: DispatchWorkItem?

    func body(content: Content) -> some View {
        ZStack {
            content

            if isPresented {
                VStack {
                    Spacer()
                    SSToast(message: message, icon: style.icon, style: style)
                        .padding(.bottom, 32)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .animation(.easeInOut(duration: 0.3), value: isPresented)
                .onAppear {
                    // Auto-dismiss after duration
                    workItem?.cancel()
                    let item = DispatchWorkItem {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isPresented = false
                        }
                    }
                    workItem = item
                    DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: item)
                }
                .onDisappear {
                    workItem?.cancel()
                    workItem = nil
                }
            }
        }
    }
}

// MARK: - View Extension

extension View {
    /// Presents a toast at the bottom of the screen.
    /// - Parameters:
    ///   - isPresented: Binding to control visibility.
    ///   - message: The message to display.
    ///   - style: The toast style (default: `.success`).
    ///   - duration: How long to show the toast in seconds (default: `2.0`).
    func toast(
        isPresented: Binding<Bool>,
        message: String,
        style: SSToast.ToastStyle = .success,
        duration: Double = 2.0
    ) -> some View {
        modifier(ToastModifier(
            isPresented: isPresented,
            message: message,
            style: style,
            duration: duration
        ))
    }
}

// MARK: - Preview

#Preview("Toast Success") {
    ZStack {
        Color.gray.ignoresSafeArea()

        VStack {
            Spacer()
            SSToast(
                message: "Report saved successfully",
                icon: "checkmark.circle.fill",
                style: .success
            )
            .padding(.bottom, 32)
        }
    }
}

#Preview("Toast Error") {
    ZStack {
        Color.gray.ignoresSafeArea()

        VStack {
            Spacer()
            SSToast(
                message: "Failed to save report",
                icon: "exclamationmark.circle.fill",
                style: .error
            )
            .padding(.bottom, 32)
        }
    }
}
