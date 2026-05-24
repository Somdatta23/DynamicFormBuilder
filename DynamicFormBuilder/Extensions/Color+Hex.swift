//
//  Color+Hex.swift
//  DynamicFormBuilder
//
//  Converts hex color strings (e.g., "#FF0000") to SwiftUI Color values.
//  Used by the theme system to apply server-driven colors.
//

import SwiftUI

extension Color {

    /// Creates a `Color` from a hex string.
    ///
    /// Supports formats:
    /// - `"#RRGGBB"` (with hash prefix)
    /// - `"RRGGBB"` (without hash prefix)
    ///
    /// Falls back to `.clear` if the string is malformed — never crashes.
    ///
    /// - Parameter hex: A 6-character hex color string, optionally prefixed with "#".
    init(hex: String) {
        let sanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        let hexString = sanitized.hasPrefix("#") ? String(sanitized.dropFirst()) : sanitized

        // Validate: must be exactly 6 hex characters
        guard hexString.count == 6,
              let hexNumber = UInt64(hexString, radix: 16) else {
            self = .clear
            return
        }

        let red   = Double((hexNumber & 0xFF0000) >> 16) / 255.0
        let green = Double((hexNumber & 0x00FF00) >> 8) / 255.0
        let blue  = Double(hexNumber & 0x0000FF) / 255.0

        self.init(red: red, green: green, blue: blue)
    }
}
