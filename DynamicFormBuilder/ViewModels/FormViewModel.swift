//
//  FormViewModel.swift
//  DynamicFormBuilder
//
//  The central ViewModel for the dynamic form.
//
//  KEY DESIGN DECISIONS:
//
//  1. Dictionary-based state: `[String: FormValue]` instead of per-field @State.
//     In SDUI, fields are unknown at compile time. A dictionary naturally maps
//     any number of runtime field IDs to their values.
//
//  2. Binding helpers: SwiftUI components need `Binding<T>`, but our state is
//     a dictionary. The `stringBinding(for:)`, `boolBinding(for:)` methods
//     bridge this gap — they create live Bindings that read/write the dictionary.
//
//  3. Centralized validation: Called on-demand (save button), not on every keystroke.
//     This is a UX choice — showing errors only after submission reduces noise.
//     Errors auto-clear when the user edits the field.
//

import SwiftUI
import Combine

final class FormViewModel: ObservableObject {
    // MARK: - Published State

    /// The decoded form schema. `nil` until loading completes.
    @Published private(set) var schema: FormSchema?

    /// All field values, keyed by field `id`.
    /// This is the single source of truth for the entire form's state.
    @Published var formValues: [String: FormValue] = [:]

    /// Validation errors, keyed by field `id`.
    /// Empty when the form is valid or hasn't been validated yet.
    @Published private(set) var validationErrors: [String: String] = [:]

    /// Set when JSON loading fails. Drives the error state UI.
    @Published private(set) var loadError: String?

    /// Set to `true` after a successful form submission. Triggers the success alert.
    @Published var isSubmitted: Bool = false

    // MARK: - Computed Properties

    /// Fields that should be rendered in the UI.
    /// Unknown types are filtered out — they never reach the view layer.
    var visibleFields: [FormField] {
        schema?.fields.filter { $0.type != .unknown } ?? []
    }

    /// The active theme, with a fallback for error states.
    var theme: FormTheme {
        schema?.theme ?? .fallback
    }

    // MARK: - Loading

    /// Loads the form schema from the app bundle and initializes default values.
    ///
    /// - Parameter filename: The JSON filename without extension. Defaults to "form_schema".
    func loadForm(from filename: String = "form_schema") {
        let result = JSONLoader.load(FormSchema.self, from: filename)

        switch result {
        case .success(let schema):
            self.schema = schema
            self.loadError = nil
            initializeDefaults()

        case .failure(let error):
            self.loadError = error.localizedDescription
            self.schema = nil
        }
    }

    // MARK: - Default Value Initialization

    /// Pre-populates the form state dictionary with default values from the schema.
    ///
    /// Called once after successful JSON loading. Each field type gets an
    /// appropriate initial value:
    /// - TEXT → empty string
    /// - DROPDOWN → pre-selected `default_values` (validated against available options)
    /// - TOGGLE → `default_value` from JSON, or `false`
    /// - CHECKBOX → `false` (unchecked)
    private func initializeDefaults() {
        guard let fields = schema?.fields else { return }

        for field in fields {
            switch field.type {
            case .text:
                formValues[field.id] = .string("")

            case .dropdown:
                // Only pre-select defaults that actually exist in the options list.
                // This guards against stale/invalid default_values in the JSON.
                let defaults = field.defaultValues ?? []
                let validDefaults = defaults.filter { defaultId in
                    field.options?.contains { $0.id == defaultId } ?? false
                }
                formValues[field.id] = .stringArray(validDefaults)

            case .toggle:
                formValues[field.id] = .bool(field.defaultValue ?? false)

            case .checkbox:
                formValues[field.id] = .bool(false)

            case .unknown:
                // Don't allocate state for unknown types.
                break
            }
        }
    }

    // MARK: - Binding Helpers

    /// Creates a two-way `Binding<String>` for a TEXT field.
    ///
    /// This bridges SwiftUI's `TextField(text: Binding<String>)` with our
    /// `[String: FormValue]` dictionary. The binding:
    /// - GET: reads from the dictionary
    /// - SET: writes to the dictionary AND enforces max_length AND clears validation errors
    ///
    /// - Parameters:
    ///   - fieldId: The field's unique identifier (dictionary key).
    ///   - maxLength: Optional character limit. Values exceeding this are truncated.
    func stringBinding(for fieldId: String, maxLength: Int? = nil) -> Binding<String> {
        Binding<String>(
            get: { [weak self] in
                self?.formValues[fieldId]?.stringValue ?? ""
            },
            set: { [weak self] newValue in
                guard let self else { return }
                var value = newValue

                // Enforce max_length at the binding level.
                // This prevents the user from typing beyond the limit.
                if let maxLength, maxLength > 0, value.count > maxLength {
                    value = String(value.prefix(maxLength))
                }

                self.formValues[fieldId] = .string(value)
                // Clear validation error as soon as the user starts editing.
                self.validationErrors[fieldId] = nil
            }
        )
    }

    /// Creates a two-way `Binding<Bool>` for TOGGLE and CHECKBOX fields.
    func boolBinding(for fieldId: String) -> Binding<Bool> {
        Binding<Bool>(
            get: { [weak self] in
                self?.formValues[fieldId]?.boolValue ?? false
            },
            set: { [weak self] newValue in
                guard let self else { return }
                self.formValues[fieldId] = .bool(newValue)
                self.validationErrors[fieldId] = nil
            }
        )
    }

    // MARK: - Dropdown Helpers

    /// Selects a single option for a single-select dropdown.
    /// Replaces any previous selection.
    func selectSingleOption(_ optionId: String, for fieldId: String) {
        formValues[fieldId] = .stringArray([optionId])
        validationErrors[fieldId] = nil
    }

    /// Toggles an option in a multi-select dropdown.
    /// If the option is already selected, it's removed. Otherwise, it's added.
    func toggleOption(_ optionId: String, for fieldId: String) {
        var current = formValues[fieldId]?.stringArrayValue ?? []
        if current.contains(optionId) {
            current.removeAll { $0 == optionId }
        } else {
            current.append(optionId)
        }
        formValues[fieldId] = .stringArray(current)
        validationErrors[fieldId] = nil
    }

    // MARK: - Validation

    /// Validates all visible fields and populates `validationErrors`.
    ///
    /// Returns `true` if all validations pass.
    ///
    /// Validation rules:
    /// | Field Type | Rule |
    /// |-----------|------|
    /// | TEXT (required) | Must not be empty (whitespace-only counts as empty) |
    /// | DROPDOWN (required) | Must have at least one selection |
    /// | CHECKBOX (required) | Must be checked (`true`) |
    /// | TOGGLE | Always valid (it always has a bool value) |
    @discardableResult
    func validate() -> Bool {
        var errors: [String: String] = [:]

        for field in visibleFields {
            // Skip non-required fields — they're always valid
            guard field.required else { continue }

            let value = formValues[field.id]

            switch field.type {
            case .text:
                let text = value?.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                if text.isEmpty {
                    errors[field.id] = "\(field.label) is required"
                }

            case .dropdown:
                let selected = value?.stringArrayValue ?? []
                if selected.isEmpty {
                    let noun = field.allowMultiple == true ? "at least one option" : "an option"
                    errors[field.id] = "Please select \(noun) for \(field.label)"
                }

            case .checkbox:
                if value?.boolValue != true {
                    errors[field.id] = "\(field.label) must be accepted"
                }

            case .toggle, .unknown:
                // Toggles always have a value; unknowns are not visible.
                break
            }
        }

        validationErrors = errors
        return errors.isEmpty
    }

    // MARK: - Submission

    /// Validates the form and, if valid, prints a clean payload to the console.
    func submitForm() {
        guard validate() else {
            print("⚠️ Form validation failed. \(validationErrors.count) error(s).")
            return
        }

        // Build the payload dictionary
        var payload: [String: Any] = [:]

        for field in visibleFields {
            if let value = formValues[field.id] {
                payload[field.id] = value.displayValue
            }
        }

        print("✅ Form submitted successfully!")
        print("📋 Payload:")

        // Sort by key for consistent, readable output
        for (key, value) in payload.sorted(by: { $0.key < $1.key }) {
            print("  \(key): \(value)")
        }

        isSubmitted = true
    }
}

