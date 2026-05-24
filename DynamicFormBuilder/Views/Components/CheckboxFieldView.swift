//
//  CheckboxFieldView.swift
//  DynamicFormBuilder
//
//  Renders CHECKBOX fields with:
//  - Custom checkbox UI (SF Symbol based — no native checkbox in SwiftUI)
//  - Label with optional embedded clickable link (from metadata)
//  - Required indicator
//
//  LINK HANDLING:
//  When `metadata.link_text` and `metadata.link_url` are provided, we
//  replace that portion of the label with a Markdown link and render it
//  using `AttributedString(markdown:)`. This makes the link text tappable
//  and styled with the theme's primary color — all within a single Text view.
//

import SwiftUI

struct CheckboxFieldView: View {
    let field: FormField
    @ObservedObject var viewModel: FormViewModel
    let theme: FormTheme

    private var isChecked: Bool {
        viewModel.formValues[field.id]?.boolValue ?? false
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // MARK: - Checkbox Icon
            Button {
                viewModel.boolBinding(for: field.id).wrappedValue.toggle()
            } label: {
                Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                    .font(.title3)
                    .foregroundColor(isChecked ? theme.primary : theme.text.opacity(0.5))
            }
            .buttonStyle(.plain)

            // MARK: - Label + Link
            VStack(alignment: .leading, spacing: 4) {
                labelView

                if field.required {
                    Text("Required")
                        .font(.caption2)
                        .foregroundColor(theme.text.opacity(0.4))
                }
            }
        }
        .padding(12)
        .background(theme.fieldBackground)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(
                    viewModel.validationErrors[field.id] != nil
                        ? theme.error
                        : theme.border,
                    lineWidth: 1
                )
        )
    }

    // MARK: - Label View

    /// Renders the label text, optionally with an embedded Markdown link.
    ///
    /// If `metadata` provides `link_text` and `link_url`, we build a Markdown
    /// string and parse it with `AttributedString(markdown:)`. This gives us
    /// a tappable link within the Text view — no need for separate Link views
    /// or complex text splitting.
    @ViewBuilder
    private var labelView: some View {
        if let metadata = field.metadata,
           let linkText = metadata.linkText,
           let urlString = metadata.linkUrl,
           let _ = URL(string: urlString) {

            // Build markdown: "I agree to the [Terms and Conditions](https://...)"
            let markdownString = field.label.replacingOccurrences(
                of: linkText,
                with: "[\(linkText)](\(urlString))"
            )

            if let attributedString = try? AttributedString(markdown: markdownString) {
                Text(attributedString)
                    .font(.subheadline)
                    .foregroundColor(theme.text)
                    .tint(theme.primary) // Colors the link text
            } else {
                // Fallback if markdown parsing fails
                plainLabel
            }
        } else {
            plainLabel
        }
    }

    /// Plain label without any links.
    private var plainLabel: some View {
        Text(field.label)
            .font(.subheadline)
            .foregroundColor(theme.text)
    }
}
