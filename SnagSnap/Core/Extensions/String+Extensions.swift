import Foundation

// MARK: - Validation

extension String {
    /// Returns `true` if the string is empty or contains only whitespace.
    var isBlank: Bool {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Returns `true` if the string contains at least one non-whitespace character.
    var isNotBlank: Bool {
        !isBlank
    }

    /// Returns the string with leading and trailing whitespace removed.
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Truncation

extension String {
    /// Truncates the string to the specified length, appending a trailing
    /// indicator (e.g. `"..."`) if truncation occurred.
    /// - Parameters:
    ///   - length: Maximum number of characters to keep.
    ///   - trailing: String appended when truncated (default `"..."`).
    /// - Returns: The truncated string.
    func truncated(to length: Int, trailing: String = "...") -> String {
        guard count > length else { return self }
        let maxLength = max(length - trailing.count, 0)
        return String(prefix(maxLength)) + trailing
    }

    /// Truncates the string at word boundaries up to the given character limit,
    /// appending a trailing indicator if needed.
    /// - Parameters:
    ///   - limit: Maximum character count.
    ///   - trailing: String appended when truncated (default `"..."`).
    /// - Returns: The truncated string respecting word boundaries.
    func truncatedAtWordBoundary(to limit: Int, trailing: String = "...") -> String {
        guard count > limit else { return self }

        let endIndex = index(startIndex, offsetBy: limit)
        let substring = self[..<endIndex]

        if let lastSpace = substring.lastIndex(of: " ") {
            return String(self[..<lastSpace]) + trailing
        }

        return truncated(to: limit, trailing: trailing)
    }
}

// MARK: - Lines

extension String {
    /// Splits the string into lines (separated by newline characters).
    var lines: [String] {
        components(separatedBy: .newlines)
    }

    /// Returns the number of lines in the string.
    var lineCount: Int {
        lines.count
    }
}

// MARK: - Preview Helpers

#if canImport(SwiftUI)
import SwiftUI

#Preview("String Extensions") {
    VStack(alignment: .leading, spacing: Theme.spacingL) {
        Group {
            StringRow(label: "isBlank (whitespace)", value: "   ".isBlank.description)
            StringRow(label: "isBlank (text)", value: "Hello".isBlank.description)
            StringRow(label: "isNotBlank", value: "Hello".isNotBlank.description)
        }

        Divider()

        Group {
            StringRow(
                label: "trimmed",
                value: "  hello world  ".trimmed
            )
            StringRow(
                label: "truncated",
                value: "A very long description that needs cutting".truncated(to: 20)
            )
            StringRow(
                label: "word boundary",
                value: "A very long description that needs cutting".truncatedAtWordBoundary(to: 25)
            )
        }
    }
    .padding(Theme.spacingL)
    .background(Theme.background)
}

private struct StringRow: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingXS) {
            Text(label)
                .font(Theme.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(Theme.bodyMedium)
                .foregroundStyle(.primary)
        }
    }
}
#endif
