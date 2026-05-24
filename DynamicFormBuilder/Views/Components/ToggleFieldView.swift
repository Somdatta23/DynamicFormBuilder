//
//  ToggleFieldView.swift
//  DynamicFormBuilder
//
//  Renders TOGGLE fields as a native SwiftUI Toggle.
//
//  IMPORTANT: The label is rendered INSIDE the Toggle closure (not by
//  FieldRendererView). This is because:
//  1. FieldRendererView skips the external label for .toggle types
//  2. SwiftUI Toggle expects its label in the closure for proper layout
//     (label on the left, switch on the right — standard iOS convention)
//
//  This makes ToggleFieldView fully self-contained for label rendering.
//

import SwiftUI

struct ToggleFieldView: View {
    let field: FormField
    @ObservedObject var viewModel: FormViewModel
    let theme: FormTheme

    var body: some View {
        Toggle(isOn: viewModel.boolBinding(for: field.id)) {
            // Label rendered here — NOT by FieldRendererView.
            // Using the label from JSON, with a safe fallback.
            Text(field.label.isEmpty ? "Toggle" : field.label)
                .font(.subheadline.weight(.medium))
                .foregroundColor(theme.text)
        }
        .tint(theme.primary)
        .padding(12)
        .background(theme.fieldBackground)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(theme.border, lineWidth: 1)
        )
    }
}
