//
//  TextFieldView.swift
//  DynamicFormBuilder
//
//  Renders TEXT fields with 5 subtype variants.
//
//  SUBTYPE BEHAVIOR:
//  ┌───────────┬─────────────────────────────────────────────────────┐
//  │ Subtype   │ Behavior                                          │
//  ├───────────┼─────────────────────────────────────────────────────┤
//  │ PLAIN     │ Standard single-line TextField                     │
//  │ MULTILINE │ TextField with vertical axis (3-6 lines)           │
//  │ NUMBER    │ TextField + .numberPad keyboard                    │
//  │ URI       │ TextField + .URL keyboard + no autocap             │
//  │ SECURE    │ SecureField (password dots)                        │
//  └───────────┴─────────────────────────────────────────────────────┘
//
//  FEATURES:
//  - Character counter when max_length is set
//  - Input truncation enforced at the Binding level (not onChange)
//  - Themed border, background, and text colors
//  - Error state border highlight
//

import SwiftUI

struct TextFieldView: View {
    let field: FormField
    @ObservedObject var viewModel: FormViewModel
    let theme: FormTheme

    /// The two-way binding to the ViewModel's state dictionary.
    /// Max length enforcement happens inside the binding's setter.
    private var text: Binding<String> {
        viewModel.stringBinding(for: field.id, maxLength: field.effectiveMaxLength)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // The appropriate field input based on subtype
            fieldInput
                .padding(12)
                .background(theme.fieldBackground)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(borderColor, lineWidth: 1)
                )

            // Character counter (only shown when max_length exists)
            if let maxLength = field.effectiveMaxLength {
                HStack {
                    Spacer()
                    Text("\(text.wrappedValue.count) / \(maxLength)")
                        .font(.caption)
                        .foregroundColor(
                            text.wrappedValue.count >= maxLength
                                ? theme.error
                                : theme.text.opacity(0.5)
                        )
                }
            }
        }
    }

    // MARK: - Field Input (subtype routing)

    @ViewBuilder
    private var fieldInput: some View {
        let subtype = field.subtype ?? .plain

        switch subtype {
        case .secure:
            // SecureField hides input with dots — appropriate for passwords.
            SecureField(field.placeholder ?? "", text: text)
                .foregroundColor(theme.text)

        case .multiline:
            // TextField with vertical axis expands to multiple lines.
            // lineLimit(3...6) gives a range: starts at 3 lines, grows to 6.
            TextField(field.placeholder ?? "", text: text, axis: .vertical)
                .lineLimit(3...6)
                .foregroundColor(theme.text)

        case .number:
            // .numberPad shows only digits — no decimal, no negative.
            TextField(field.placeholder ?? "", text: text)
                .keyboardType(.numberPad)
                .foregroundColor(theme.text)

        case .uri:
            // URL keyboard includes common URL characters (., /, .com).
            // Autocapitalization and autocorrect are disabled because URLs are case-sensitive.
            TextField(field.placeholder ?? "", text: text)
                .keyboardType(.URL)
                .textContentType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .foregroundColor(theme.text)

        case .plain, .unknown:
            // Default single-line text field.
            // .unknown subtype falls through here — safe fallback.
            TextField(field.placeholder ?? "", text: text)
                .foregroundColor(theme.text)
        }
    }

    // MARK: - Helpers

    /// Border turns red when there's a validation error for this field.
    private var borderColor: Color {
        viewModel.validationErrors[field.id] != nil ? theme.error : theme.border
    }
}
