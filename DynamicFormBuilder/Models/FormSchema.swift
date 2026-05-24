//
//  FormSchema.swift
//  DynamicFormBuilder
//
//  Top-level form schema decoded from the JSON bundle resource.
//
//  Key technique: LOSSY ARRAY DECODING
//  In standard Codable, if ANY element in an array fails to decode,
//  the ENTIRE array fails. That's unacceptable for SDUI — one bad field
//  from the backend should never take down the whole form.
//
//  Our custom init(from:) decodes each field individually and silently
//  skips any that fail. This is a production-critical pattern.
//

import Foundation

/// The top-level form schema containing the title, theme, and dynamic fields.
struct FormSchema: Decodable {
    let formTitle: String
    let theme: FormTheme
    let fields: [FormField]

    enum CodingKeys: String, CodingKey {
        case formTitle
        case theme
        case fields
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        formTitle = try container.decode(String.self, forKey: .formTitle)
        theme = try container.decode(FormTheme.self, forKey: .theme)

        // --- Lossy Array Decoding ---
        // Instead of: fields = try container.decode([FormField].self, forKey: .fields)
        // We decode each element individually and skip failures.
        var fieldsContainer = try container.nestedUnkeyedContainer(forKey: .fields)
        var decodedFields: [FormField] = []

        while !fieldsContainer.isAtEnd {
            if let field = try? fieldsContainer.decode(FormField.self) {
                decodedFields.append(field)
            } else {
                // IMPORTANT: We must still advance the container's internal index
                // past the failed element. Without this, we'd be stuck in an
                // infinite loop trying to decode the same broken element.
                _ = try? fieldsContainer.decode(AnyDecodable.self)
            }
        }

        fields = decodedFields
    }
}

// MARK: - AnyDecodable Helper

/// A throwaway type used to advance the decoder past a malformed element.
///
/// When a `FormField` fails to decode, we need to "consume" the broken JSON
/// object so the unkeyed container moves to the next element.
/// This type accepts any valid JSON value without caring about its structure.
private struct AnyDecodable: Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        // Try each JSON type in order. At least one will succeed for valid JSON.
        if container.decodeNil() { return }
        if let _ = try? container.decode(Bool.self) { return }
        if let _ = try? container.decode(Int.self) { return }
        if let _ = try? container.decode(Double.self) { return }
        if let _ = try? container.decode(String.self) { return }
        if let _ = try? container.decode([AnyDecodable].self) { return }
        if let _ = try? container.decode([String: AnyDecodable].self) { return }
    }
}
