//
//  FormValue.swift
//  DynamicFormBuilder
//
//  A type-erased container for form field values.
//
//  Why an enum instead of `Any`?
//  - `Any` can't conform to `Equatable`, so SwiftUI can't diff changes efficiently
//  - `Any` requires force-casting at every access site → crash risk
//  - An enum gives us exhaustive `switch` statements → the compiler enforces correctness
//

import Foundation

/// Represents the value of any form field.
///
/// The dynamic form stores all field values as `[String: FormValue]`.
/// Each variant maps to one or more field types:
/// - `.string` → TEXT fields
/// - `.bool` → TOGGLE, CHECKBOX fields
/// - `.stringArray` → DROPDOWN fields (both single and multi-select)
enum FormValue: Equatable {
    case string(String)
    case bool(Bool)
    case stringArray([String])

    // MARK: - Type-Safe Accessors

    /// Extracts the string value, or `nil` if this isn't a `.string` case.
    var stringValue: String? {
        if case .string(let value) = self { return value }
        return nil
    }

    /// Extracts the bool value, or `nil` if this isn't a `.bool` case.
    var boolValue: Bool? {
        if case .bool(let value) = self { return value }
        return nil
    }

    /// Extracts the string array value, or `nil` if this isn't a `.stringArray` case.
    var stringArrayValue: [String]? {
        if case .stringArray(let value) = self { return value }
        return nil
    }

    // MARK: - Validation Helpers

    /// Returns `true` if the value is semantically "empty" for validation purposes.
    ///
    /// - `.string("")` → empty (whitespace-only also counts as empty)
    /// - `.bool(false)` → empty (unchecked checkbox)
    /// - `.stringArray([])` → empty (no selections)
    var isEmpty: Bool {
        switch self {
        case .string(let value):
            return value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .bool(let value):
            return !value
        case .stringArray(let value):
            return value.isEmpty
        }
    }

    // MARK: - Payload Display

    /// Returns the raw value for console printing / payload construction.
    var displayValue: Any {
        switch self {
        case .string(let value):  return value
        case .bool(let value):    return value
        case .stringArray(let value): return value
        }
    }
}
