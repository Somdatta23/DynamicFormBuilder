//
//  FieldRendererView.swift
//  DynamicFormBuilder
//
//  The SDUI routing layer — the single point where field types
//  are mapped to concrete SwiftUI components.
//
//  WHY A SINGLE SWITCH?
//  Centralizing the routing means:
//  - Adding a new field type = one new case + one new view file
//  - The entire type→component mapping is visible in one place
//  - Reviewers can instantly see all supported types
//
//  This view also handles the shared responsibilities:
//  - Rendering the field label (with required indicator)
//  - Showing validation errors below the field
//

import SwiftUI

struct FieldRendererView: View {
    let field: FormField
    @ObservedObject var viewModel: FormViewModel
    let theme: FormTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {

            // MARK: - Field Label
            // Rendered here (not in each component) for consistency.
            // EXCEPTIONS:
            // - CHECKBOX: renders its own label with optional embedded link
            // - TOGGLE: renders label inside Toggle() closure for native iOS layout
            //   (label left, switch right). Both handle their own labels internally.
            if field.type != .checkbox && field.type != .toggle {
                HStack(spacing: 4) {
                    Text(field.label)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(theme.text)

                    if field.required {
                        Text("*")
                            .foregroundColor(theme.error)
                    }
                }
            }

            // MARK: - Component Router (the SDUI engine)
            switch field.type {
            case .text:
                TextFieldView(field: field, viewModel: viewModel, theme: theme)

            case .dropdown:
                DropdownFieldView(field: field, viewModel: viewModel, theme: theme)

            case .toggle:
                ToggleFieldView(field: field, viewModel: viewModel, theme: theme)

            case .checkbox:
                CheckboxFieldView(field: field, viewModel: viewModel, theme: theme)

            case .unknown:
                UnknownFieldView(field: field, theme: theme)
            }

            // MARK: - Validation Error
            // Shared across all field types — avoids duplicating error
            // display logic in every component.
            if let error = viewModel.validationErrors[field.id] {
                FieldErrorView(message: error, theme: theme)
            }
        }
    }
}
