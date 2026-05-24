//
//  FieldErrorView.swift
//  DynamicFormBuilder
//
//  Reusable validation error label.
//  Displayed below any field that has a validation error.
//

import SwiftUI

/// A small, red error message with an icon.
///
/// Shared across all field types — the `FieldRendererView` places this
/// below any field whose `id` has an entry in `validationErrors`.
struct FieldErrorView: View {
    let message: String
    let theme: FormTheme

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.caption)

            Text(message)
                .font(.caption)
        }
        .foregroundColor(theme.error)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
}
