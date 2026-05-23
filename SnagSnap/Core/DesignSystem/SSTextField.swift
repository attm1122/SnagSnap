import SwiftUI

// MARK: - SSTextField

/// A styled text field with icon support, validation state, error message,
/// character limit display, secure-text option, and a clear button.
struct SSTextField: View {
    let title: String
    let placeholder: String
    let icon: String?
    let isSecure: Bool
    let errorMessage: String?
    let characterLimit: Int?
    @Binding var text: String

    @State private var isEditing = false
    @FocusState private var isFocused: Bool

    // MARK: - Initializer

    /// Creates a new ``SSTextField``.
    /// - Parameters:
    ///   - title: Label displayed above the text field.
    ///   - placeholder: Placeholder text shown when empty.
    ///   - text: Bound text value.
    ///   - icon: Optional SF Symbol name shown on the leading edge.
    ///   - isSecure: Whether to mask input (like a password field).
    ///   - errorMessage: Optional validation error shown below the field.
    ///   - characterLimit: Optional maximum character count shown as a counter.
    init(
        _ title: String,
        placeholder: String,
        text: Binding<String>,
        icon: String? = nil,
        isSecure: Bool = false,
        errorMessage: String? = nil,
        characterLimit: Int? = nil
    ) {
        self.title = title
        self.placeholder = placeholder
        self._text = text
        self.icon = icon
        self.isSecure = isSecure
        self.errorMessage = errorMessage
        self.characterLimit = characterLimit
    }

    // MARK: - Validation State

    private var hasError: Bool {
        errorMessage != nil
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingXS) {
            // Title label
            Text(title)
                .font(Theme.callout)
                .foregroundStyle(.primary)

            // Input row
            HStack(spacing: Theme.spacingS) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: Theme.iconSizeM))
                        .foregroundStyle(hasError ? Theme.error : .secondary)
                }

                if isSecure {
                    SecureField(placeholder, text: $text)
                        .font(Theme.body)
                        .focused($isFocused)
                        .textContentType(.password)
                } else {
                    TextField(placeholder, text: $text)
                        .font(Theme.body)
                        .focused($isFocused)
                }

                // Clear button
                if !text.isEmpty, !isSecure {
                    Button(action: { text = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: Theme.iconSizeM))
                            .foregroundStyle(.secondary.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear text")
                }
            }
            .padding(.horizontal, Theme.spacingM)
            .frame(height: Theme.buttonHeight)
            .background(Theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusM, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadiusM, style: .continuous)
                    .stroke(borderColor, lineWidth: 1.5)
            )

            // Footer row: error message and/or character counter
            HStack {
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .font(Theme.caption)
                        .foregroundStyle(Theme.error)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                Spacer()

                if let limit = characterLimit {
                    Text("\(text.count)/\(limit)")
                        .font(Theme.caption)
                        .foregroundStyle(text.count > limit ? Theme.error : .secondary)
                }
            }
        }
    }

    // MARK: - Border Color

    private var borderColor: Color {
        if hasError {
            return Theme.error
        }
        return isFocused ? Theme.secondaryAccent.opacity(0.5) : Color.gray.opacity(0.2)
    }
}

// MARK: - Preview

#Preview("SSTextField Variants") {
    @Previewable @State var name = ""
    @Previewable @State var email = "builder@example.com"
    @Previewable @State var password = "secret"
    @Previewable @State var longText = ""
    @Previewable @State var invalidEmail = "not-an-email"

    ScrollView {
        VStack(spacing: Theme.spacingL) {
            SSTextField(
                "Full Name",
                placeholder: "Enter your name",
                text: $name,
                icon: "person"
            )

            SSTextField(
                "Email Address",
                placeholder: "you@example.com",
                text: $email,
                icon: "envelope"
            )

            SSTextField(
                "Password",
                placeholder: "Enter password",
                text: $password,
                icon: "lock",
                isSecure: true
            )

            SSTextField(
                "Description",
                placeholder: "Brief description…",
                text: $longText,
                icon: "text.alignleft",
                characterLimit: 120
            )

            SSTextField(
                "Email",
                placeholder: "you@example.com",
                text: $invalidEmail,
                icon: "envelope",
                errorMessage: "Please enter a valid email address."
            )
        }
        .padding(Theme.spacingM)
    }
    .background(Theme.background)
}
