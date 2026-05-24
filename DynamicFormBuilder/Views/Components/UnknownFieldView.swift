//
//  UnknownFieldView.swift
//  DynamicFormBuilder
//
//  Graceful fallback for unrecognized field types.
//
//  This is a critical part of the SDUI contract:
//  The app must NEVER crash on unknown types. If the backend adds
//  "SLIDER" or "DATE_PICKER" tomorrow, the app simply renders nothing
//  for that field — the rest of the form works perfectly.
//
//  In DEBUG builds, we show a subtle indicator so developers can see
//  what's being skipped. In RELEASE builds, it's invisible.
//

import SwiftUI

struct UnknownFieldView: View {
    let field: FormField
    let theme: FormTheme

    var body: some View {
        #if DEBUG
        HStack(spacing: 8) {
            Image(systemName: "questionmark.diamond")
                .foregroundColor(.orange.opacity(0.6))

            Text("Unsupported field: \"\(field.id)\"")
                .font(.caption)
                .foregroundColor(theme.text.opacity(0.4))
        }
        .padding(8)
        .background(theme.fieldBackground.opacity(0.5))
        .cornerRadius(8)
        #else
        EmptyView()
        #endif
    }
}
