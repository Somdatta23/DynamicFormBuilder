//
//  DropdownFieldView.swift
//  DynamicFormBuilder
//
//  Renders DROPDOWN fields with two modes:
//  - Single select (allow_multiple == false): Tap to open sheet, pick one option
//  - Multi select (allow_multiple == true): Tap to open sheet, toggle multiple options
//
//  KEY DESIGN: UI shows option `label`, state stores option `id`.
//  This decoupling means labels can be localized or changed without
//  breaking stored selections.
//
//  WHY A SHEET INSTEAD OF NATIVE PICKER?
//  SwiftUI's built-in Picker with .menu style can look cramped and
//  doesn't support multi-select. A bottom sheet provides:
//  - Consistent UI for both single and multi-select
//  - More room for option labels
//  - Clear visual feedback (checkmarks)
//  - Better accessibility
//

import SwiftUI

struct DropdownFieldView: View {
    let field: FormField
    @ObservedObject var viewModel: FormViewModel
    let theme: FormTheme

    @State private var isSheetPresented = false

    // MARK: - Computed Properties

    private var isMultiSelect: Bool {
        field.allowMultiple ?? false
    }

    private var selectedIds: [String] {
        viewModel.formValues[field.id]?.stringArrayValue ?? []
    }

    private var options: [DropdownOption] {
        field.options ?? []
    }

    /// Display text showing current selection(s) as human-readable labels.
    private var displayText: String {
        let selectedLabels = options
            .filter { selectedIds.contains($0.id) }
            .map(\.label)

        if selectedLabels.isEmpty {
            return "Select…"
        }
        return selectedLabels.joined(separator: ", ")
    }

    // MARK: - Body

    var body: some View {
        Button {
            isSheetPresented = true
        } label: {
            HStack {
                Text(displayText)
                    .foregroundColor(
                        selectedIds.isEmpty
                            ? theme.text.opacity(0.4)
                            : theme.text
                    )
                    .lineLimit(1)

                Spacer()

                Image(systemName: "chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(theme.text.opacity(0.5))
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
        .sheet(isPresented: $isSheetPresented) {
            selectionSheet
        }
    }

    // MARK: - Selection Sheet

    @ViewBuilder
    private var selectionSheet: some View {
        NavigationView {
            List {
                if options.isEmpty {
                    // Edge case: dropdown with no options
                    Text("No options available")
                        .foregroundColor(.secondary)
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(options) { option in
                        optionRow(option)
                    }
                }
            }
            .navigationTitle(field.label)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // "Done" only for multi-select (single-select auto-dismisses)
                ToolbarItem(placement: .confirmationAction) {
                    if isMultiSelect {
                        Button("Done") {
                            isSheetPresented = false
                        }
                    }
                }

                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isSheetPresented = false
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Option Row

    @ViewBuilder
    private func optionRow(_ option: DropdownOption) -> some View {
        Button {
            if isMultiSelect {
                // Toggle the option on/off
                viewModel.toggleOption(option.id, for: field.id)
            } else {
                // Select this option and dismiss
                viewModel.selectSingleOption(option.id, for: field.id)
                isSheetPresented = false
            }
        } label: {
            HStack {
                Text(option.label)
                    .foregroundColor(.primary)

                Spacer()

                // Selection indicator
                if selectedIds.contains(option.id) {
                    Image(systemName: isMultiSelect ? "checkmark.square.fill" : "checkmark.circle.fill")
                        .foregroundColor(theme.primary)
                } else {
                    Image(systemName: isMultiSelect ? "square" : "circle")
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}
