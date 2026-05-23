// SnagSnap
// KeyboardHelpers.swift
//
// View modifiers for keyboard dismissal in form views.

import SwiftUI

// MARK: - Dismiss Keyboard On Tap

/// A view modifier that dismisses the keyboard when the user taps outside a text field.
struct DismissKeyboardOnTap: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
    }
}

// MARK: - View Extensions

extension View {
    /// Dismisses the keyboard immediately when the user scrolls.
    func dismissKeyboardOnDrag() -> some View {
        self.scrollDismissesKeyboard(.immediately)
    }
}
