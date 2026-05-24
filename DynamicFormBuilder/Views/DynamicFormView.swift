//
//  DynamicFormView.swift
//  DynamicFormBuilder
//
//  The main form screen — the root view of the app.
//
//  This view manages three states:
//  1. LOADING ERROR → error message with retry button
//  2. LOADED, EMPTY → "no fields" message (edge case)
//  3. LOADED → the dynamic form with all fields + save button
//
//  Architecture notes:
//  - @StateObject creates and owns the ViewModel (single instance per view lifecycle)
//  - ScrollViewReader enables "scroll to first error" on validation failure
//  - NavigationStack provides the title bar with dark theme styling
//

import SwiftUI

struct DynamicFormView: View {
    @StateObject private var viewModel = FormViewModel()

    var body: some View {
        Group {
            if let error = viewModel.loadError {
                errorView(message: error)
            } else if viewModel.schema != nil {
                formContent
            } else {
                // Brief loading state (synchronous load, so this rarely shows)
                ProgressView("Loading form…")
            }
        }
        .onAppear {
            viewModel.loadForm()
        }
    }

    // MARK: - Form Content

    @ViewBuilder
    private var formContent: some View {
        let theme = viewModel.theme

        NavigationStack {
            ScrollViewReader { scrollProxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 20) {
                        // Render each visible field through the SDUI engine
                        ForEach(viewModel.visibleFields) { field in
                            FieldRendererView(
                                field: field,
                                viewModel: viewModel,
                                theme: theme
                            )
                            .id(field.id) // For ScrollViewReader targeting
                        }

                        // Edge case: schema loaded but no renderable fields
                        if viewModel.visibleFields.isEmpty {
                            emptyFieldsView(theme: theme)
                        }

                        // Save button
                        saveButton(theme: theme, scrollProxy: scrollProxy)
                            .padding(.top, 12)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                .background(theme.background.ignoresSafeArea())
                .navigationTitle(viewModel.schema?.formTitle ?? "Form")
                .navigationBarTitleDisplayMode(.large)
                .toolbarColorScheme(.dark, for: .navigationBar)
                .toolbarBackground(theme.background, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
            }
        }
        // Success alert after submission
        .alert("Form Submitted!", isPresented: $viewModel.isSubmitted) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your form has been submitted successfully.\nCheck the console for the payload.")
        }
    }

    // MARK: - Save Button

    @ViewBuilder
    private func saveButton(theme: FormTheme, scrollProxy: ScrollViewProxy) -> some View {
        Button {
            let isValid = viewModel.validate()

            if isValid {
                viewModel.submitForm()
            } else {
                // Scroll to the first field with a validation error.
                // This provides clear feedback — the user sees exactly
                // which field needs attention.
                if let firstErrorId = viewModel.visibleFields.first(where: {
                    viewModel.validationErrors[$0.id] != nil
                })?.id {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        scrollProxy.scrollTo(firstErrorId, anchor: .top)
                    }
                }
            }
        } label: {
            Text("Save")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(theme.primary)
                .cornerRadius(12)
        }
    }

    // MARK: - Error View (JSON load failure)

    @ViewBuilder
    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)

            Text("Failed to Load Form")
                .font(.title2.bold())

            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("Retry") {
                viewModel.loadForm()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty Fields View

    @ViewBuilder
    private func emptyFieldsView(theme: FormTheme) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(theme.text.opacity(0.5))

            Text("No fields available")
                .font(.headline)
                .foregroundColor(theme.text.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Preview

#Preview {
    DynamicFormView()
}
