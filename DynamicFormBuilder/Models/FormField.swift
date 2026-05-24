//
//  FormField.swift
//  DynamicFormBuilder
//
//  The polymorphic field model — the heart of Server-Driven UI decoding.
//
//  Design decision: Flat struct with optionals vs. enum with associated values.
//  We chose flat struct because:
//  - Simpler Codable conformance (auto-synthesized, no manual init(from:))
//  - Easier to extend (add a new optional property, done)
//  - Gracefully ignores unknown/missing properties via optionals
//  - Enums with associated values require a manual switch in init(from:) —
//    more code for the same result, harder to extend later
//

import Foundation

// MARK: - Field Type

/// The primary discriminator for SDUI routing.
///
/// Each case maps to a specific SwiftUI component.
/// The `.unknown` case ensures the app never crashes on unrecognized types —
/// the backend can add `"SLIDER"` tomorrow and our app will simply skip it.
enum FieldType: String, Decodable {
    case text = "TEXT"
    case dropdown = "DROPDOWN"
    case toggle = "TOGGLE"
    case checkbox = "CHECKBOX"
    case unknown

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = FieldType(rawValue: rawValue) ?? .unknown
    }
}

// MARK: - Text Subtype

/// Controls keyboard type, field variant, and input behavior for TEXT fields.
///
/// - `PLAIN`: Standard single-line text field
/// - `MULTILINE`: Expands vertically for longer text
/// - `NUMBER`: Shows numeric keyboard
/// - `URI`: Shows URL keyboard, disables autocapitalization
/// - `SECURE`: Renders as SecureField (password dots)
enum TextSubtype: String, Decodable {
    case plain = "PLAIN"
    case multiline = "MULTILINE"
    case number = "NUMBER"
    case uri = "URI"
    case secure = "SECURE"
    case unknown

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = TextSubtype(rawValue: rawValue) ?? .unknown
    }
}

// MARK: - Dropdown Option

/// A single selectable option in a DROPDOWN field.
///
/// The UI displays `label` to the user, but the state stores `id`.
/// This separation is important: labels can change (localization, rebranding)
/// without breaking stored values.
struct DropdownOption: Decodable, Identifiable, Hashable {
    let id: String
    let label: String
}

// MARK: - Checkbox Metadata

/// Optional metadata attached to CHECKBOX fields.
///
/// When present, allows the checkbox label to contain a clickable link
/// (e.g., "I agree to the [Terms and Conditions](url)").
struct CheckboxMetadata: Decodable {
    let linkText: String?
    let linkUrl: String?
}

// MARK: - Form Field

/// A single field in the dynamic form.
///
/// All type-specific properties are optional. Only the properties relevant
/// to a given `type` will be non-nil. For example, a TEXT field will have
/// `subtype` and `maxLength`, but `options` will be `nil`.
struct FormField: Decodable, Identifiable {
    let id: String
    let type: FieldType
    let label: String
    let placeholder: String?
    let required: Bool

    // TEXT-specific
    let subtype: TextSubtype?
    let maxLength: Int?

    // DROPDOWN-specific
    let options: [DropdownOption]?
    let allowMultiple: Bool?
    let defaultValues: [String]?

    // TOGGLE-specific
    let defaultValue: Bool?

    // CHECKBOX-specific
    let metadata: CheckboxMetadata?

    /// The effective max length, treating 0 and negative values as "no limit".
    ///
    /// Why? A max_length of 0 or -1 in the JSON is likely a mistake or sentinel value.
    /// Rather than enforcing a 0-character limit (making the field unusable),
    /// we treat it as "unrestricted".
    var effectiveMaxLength: Int? {
        guard let maxLength, maxLength > 0 else { return nil }
        return maxLength
    }
}
