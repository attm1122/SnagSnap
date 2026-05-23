import SwiftUI

// MARK: - Hex Initializer

extension Color {
    /// Creates a `Color` from a hexadecimal string.
    ///
    /// Supported formats:
    /// - `"#FF5733"` or `"FF5733"` (6-digit RGB)
    /// - `"#F53"` or `"F53"` (3-digit shorthand)
    /// - `"#FF5733FF"` or `"FF5733FF"` (8-digit RGBA)
    ///
    /// - Parameter hex: The hexadecimal color string.
    init?(hex: String) {
        let trimmed = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let scanner = Scanner(string: trimmed)
        var hexNumber: UInt64 = 0

        guard scanner.scanHexInt64(&hexNumber) else { return nil }

        let length = trimmed.count
        let r, g, b, a: CGFloat

        switch length {
        case 3:
            r = CGFloat((hexNumber & 0xF00) >> 8) / 15.0
            g = CGFloat((hexNumber & 0x0F0) >> 4) / 15.0
            b = CGFloat(hexNumber & 0x00F) / 15.0
            a = 1.0
        case 6:
            r = CGFloat((hexNumber & 0xFF0000) >> 16) / 255.0
            g = CGFloat((hexNumber & 0x00FF00) >> 8) / 255.0
            b = CGFloat(hexNumber & 0x0000FF) / 255.0
            a = 1.0
        case 8:
            r = CGFloat((hexNumber & 0xFF000000) >> 24) / 255.0
            g = CGFloat((hexNumber & 0x00FF0000) >> 16) / 255.0
            b = CGFloat((hexNumber & 0x0000FF00) >> 8) / 255.0
            a = CGFloat(hexNumber & 0x000000FF) / 255.0
        default:
            return nil
        }

        self.init(red: r, green: g, blue: b, opacity: a)
    }
}

// MARK: - Adjustments

extension Color {
    /// Returns a lighter version of this color by blending it with white.
    /// - Parameter amount: Blend amount in `0...1` (default `0.2`).
    /// - Returns: A lighter `Color`.
    func lighten(by amount: Double = 0.2) -> Color {
        blend(with: .white, by: amount)
    }

    /// Returns a darker version of this color by blending it with black.
    /// - Parameter amount: Blend amount in `0...1` (default `0.2`).
    /// - Returns: A darker `Color`.
    func darken(by amount: Double = 0.2) -> Color {
        blend(with: .black, by: amount)
    }

    /// Blends this color with another color by a given amount.
    /// - Parameters:
    ///   - other: The color to blend toward.
    ///   - amount: Blend amount in `0...1`.
    /// - Returns: The blended `Color`.
    func blend(with other: Color, by amount: Double) -> Color {
        let clamped = max(0, min(1, amount))
        let components1 = self.rgbaComponents
        let components2 = other.rgbaComponents

        let r = components1.red + (components2.red - components1.red) * clamped
        let g = components1.green + (components2.green - components1.green) * clamped
        let b = components1.blue + (components2.blue - components1.blue) * clamped
        let a = components1.alpha + (components2.alpha - components1.alpha) * clamped

        return Color(red: r, green: g, blue: b, opacity: a)
    }
}

// MARK: - Component Extraction

extension Color {
    /// The RGBA components of this color in the sRGB color space.
    var rgbaComponents: (red: Double, green: Double, blue: Double, alpha: Double) {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return (Double(red), Double(green), Double(blue), Double(alpha))
    }

    /// A hexadecimal string representation of this color (e.g. `"#FF5733"`).
    var hexString: String {
        let components = rgbaComponents
        let r = Int(components.red * 255)
        let g = Int(components.green * 255)
        let b = Int(components.blue * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

// MARK: - Preview

#Preview("Color Extensions") {
    VStack(spacing: Theme.spacingM) {
        let baseColor = Color(hex: "#1E4D8C") ?? Theme.primary

        HStack(spacing: Theme.spacingM) {
            RoundedRectangle(cornerRadius: Theme.cornerRadiusM)
                .fill(baseColor)
                .frame(width: 60, height: 60)
                .overlay(Text("Base").font(Theme.caption).foregroundStyle(.white))

            RoundedRectangle(cornerRadius: Theme.cornerRadiusM)
                .fill(baseColor.lighten(by: 0.25))
                .frame(width: 60, height: 60)
                .overlay(Text("+25%").font(Theme.caption))

            RoundedRectangle(cornerRadius: Theme.cornerRadiusM)
                .fill(baseColor.darken(by: 0.25))
                .frame(width: 60, height: 60)
                .overlay(Text("-25%").font(Theme.caption).foregroundStyle(.white))
        }

        Text("Hex: \(baseColor.hexString)")
            .font(Theme.callout)
            .foregroundStyle(.secondary)
    }
    .padding(Theme.spacingL)
    .background(Theme.background)
}
