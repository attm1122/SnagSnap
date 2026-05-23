import Foundation

// MARK: - Validation

extension String {
    /// Check if the string is empty or contains only whitespace and newlines.
    var isBlank: Bool {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Check if the string is not blank (has at least one non-whitespace character).
    var isNotBlank: Bool {
        !isBlank
    }

    /// Check if the string contains at least one non-whitespace character.
    var hasContent: Bool {
        isNotBlank
    }

    /// A trimmed version of the string (whitespace and newlines removed from both ends).
    func trimmed() -> String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Trim whitespace and newlines in place (mutating).
    mutating func trim() {
        self = trimmed()
    }

    /// Truncate the string to a maximum length, appending an ellipsis if truncated.
    ///
    /// - Parameters:
    ///   - length: Maximum number of characters.
    ///   - ellipsis: String to append when truncated (default: "…").
    /// - Returns: Truncated string.
    func truncated(to length: Int, ellipsis: String = "…") -> String {
        guard count > length else { return self }
        let maxLength = max(length - ellipsis.count, 0)
        let prefix = String(self.prefix(maxLength)).trimmed()
        return prefix + ellipsis
    }

    /// Truncate from the beginning instead of the end.
    func truncatedFromStart(to length: Int, prefix: String = "…") -> String {
        guard count > length else { return self }
        let maxLength = max(length - prefix.count, 0)
        let suffix = String(self.suffix(maxLength)).trimmed()
        return prefix + suffix
    }

    /// Check if the string is a valid email address.
    var isValidEmail: Bool {
        let regex = #"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}"#
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: self)
    }

    /// Check if the string is a valid phone number (basic international format).
    /// Accepts 7–15 digits with optional +, spaces, dashes, and parentheses.
    var isValidPhone: Bool {
        let digitsOnly = filter { $0.isNumber }
        return digitsOnly.count >= 7 && digitsOnly.count <= 15
    }

    /// Check if the string is a valid URL.
    var isValidURL: Bool {
        guard let url = URL(string: self) else { return false }
        return url.scheme != nil && url.host != nil
    }

    /// Check if the string contains only numeric characters.
    var isNumeric: Bool {
        allSatisfy { $0.isNumber }
    }

    /// Check if the string can be parsed as a Double.
    var isDouble: Bool {
        Double(self) != nil
    }

    /// Check if the string can be parsed as an Int.
    var isInt: Bool {
        Int(self) != nil
    }
}

// MARK: - Formatting

extension String {
    /// Convert the first letter to uppercase, leaving the rest unchanged.
    var firstUppercased: String {
        guard let first = first else { return self }
        return String(first).uppercased() + dropFirst()
    }

    /// Convert the first letter to uppercase and the rest to lowercase.
    var firstCapitalized: String {
        guard let first = first else { return self }
        return String(first).uppercased() + dropFirst().lowercased()
    }

    /// Remove all whitespace characters from the string.
    var removingWhitespace: String {
        components(separatedBy: .whitespacesAndNewlines).joined()
    }

    /// Remove all non-alphanumeric characters.
    var alphanumericOnly: String {
        components(separatedBy: CharacterSet.alphanumerics.inverted).joined()
    }

    /// Extract digits only from the string.
    var digitsOnly: String {
        filter { $0.isNumber }
    }

    /// Format as a phone number (e.g., "+1 (555) 123-4567").
    func formattedAsPhoneNumber() -> String {
        let digits = digitsOnly
        guard digits.count >= 10 else { return self }

        let areaCode = digits.prefix(3)
        let prefix = digits[digits.index(digits.startIndex, offsetBy: 3)..<digits.index(digits.startIndex, offsetBy: 6)]
        let line = digits.suffix(digits.count - 6)

        if digits.count > 10 {
            let country = digits.prefix(digits.count - 10)
            return "+\(country) (\(areaCode)) \(prefix)-\(line)"
        }

        return "(\(areaCode)) \(prefix)-\(line)"
    }
}

// MARK: - Padding & Filling

extension String {
    /// Pad the string to a minimum length on the left.
    func leftPadded(to length: Int, with character: Character = " ") -> String {
        guard count < length else { return self }
        let padding = String(repeating: character, count: length - count)
        return padding + self
    }

    /// Pad the string to a minimum length on the right.
    func rightPadded(to length: Int, with character: Character = " ") -> String {
        guard count < length else { return self }
        let padding = String(repeating: character, count: length - count)
        return self + padding
    }
}

// MARK: - Substring Helpers

extension String {
    /// Safely get a substring up to the specified index.
    func safePrefix(_ maxLength: Int) -> String {
        String(prefix(Swift.min(maxLength, count)))
    }

    /// Safely get a substring from the specified index to the end.
    func safeSuffix(_ maxLength: Int) -> String {
        String(suffix(Swift.min(maxLength, count)))
    }

    /// Get substring at a specific range safely.
    subscript(safe range: Range<Int>) -> String? {
        guard range.lowerBound >= 0, range.upperBound <= count else { return nil }
        let start = index(startIndex, offsetBy: range.lowerBound)
        let end = index(startIndex, offsetBy: range.upperBound)
        return String(self[start..<end])
    }
}

// MARK: - URL Helpers

extension String {
    /// Convert to a URL, returning nil if invalid.
    var asURL: URL? {
        URL(string: self)
    }

    /// Convert to a URL, adding percent encoding if needed.
    var asEncodedURL: URL? {
        let encoded = addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? self
        return URL(string: encoded)
    }
}

// MARK: - Data Conversion

extension String {
    /// Convert to Data using UTF-8 encoding.
    var utf8Data: Data? {
        data(using: .utf8)
    }

    /// Convert hex string to Data.
    var hexData: Data? {
        var data = Data()
        let trimmed = removingWhitespace
        guard trimmed.count % 2 == 0 else { return nil }

        for i in stride(from: 0, to: trimmed.count, by: 2) {
            let start = trimmed.index(trimmed.startIndex, offsetBy: i)
            let end = trimmed.index(start, offsetBy: 2)
            let byteString = trimmed[start..<end]
            if let byte = UInt8(byteString, radix: 16) {
                data.append(byte)
            } else {
                return nil
            }
        }
        return data
    }
}
