//
//  Theme.swift
//  DynamicFormBuilder
//
//  The theme model for server-driven styling.
//
//  Design: Raw hex strings are Decodable properties, computed Color
//  properties provide the SwiftUI-ready values. This separation means
//  the Codable layer stays clean (just strings) and the view layer
//  gets proper Color types.
//

import SwiftUI

/// Theme configuration decoded from the JSON schema.
///
/// Provides hex strings as stored properties (for Codable) and
/// computed SwiftUI `Color` properties (for views).
struct FormTheme: Decodable {

    // MARK: - Raw Values (from JSON)

    let backgroundColor: String
    let textColor: String
    let borderColor: String
    let errorColor: String
    let primaryColor: String
    let fieldBackgroundColor: String

    // MARK: - Computed SwiftUI Colors

    var background: Color { Color(hex: backgroundColor) }
    var text: Color { Color(hex: textColor) }
    var border: Color { Color(hex: borderColor) }
    var error: Color { Color(hex: errorColor) }
    var primary: Color { Color(hex: primaryColor) }
    var fieldBackground: Color { Color(hex: fieldBackgroundColor) }

    // MARK: - Fallback

    /// A sensible default theme used when JSON fails to load.
    ///
    /// Matches the dark theme from the schema so the app always looks
    /// intentional, even in error states.
    static let fallback = FormTheme(
        backgroundColor: "#1C1C1E",
        textColor: "#FFFFFF",
        borderColor: "#3A3A3C",
        errorColor: "#FF453A",
        primaryColor: "#0A84FF",
        fieldBackgroundColor: "#2C2C2E"
    )
}
