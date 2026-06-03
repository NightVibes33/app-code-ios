//
//  searchBar.swift
//  Code App
//
//  Created by Ken Chung on 5/12/2020.
//

import SwiftUI

struct SearchBar: View {

    @Binding var text: String
    @State private var isEditing = false
    let searchAction: (() -> Void)?
    var clearAction: (() -> Void)? = nil
    let placeholder: String
    let cornerRadius: CGFloat?

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Color(id: "tab.inactiveForeground"))
                .font(.subheadline.weight(.semibold))

            TextField(placeholder, text: $text, onCommit: { searchAction?() })
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .submitLabel(.search)
                .onTapGesture {
                    self.isEditing = true
                }

            if isEditing && text != "" {
                Button {
                    self.text = ""
                    clearAction?()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color(id: "tab.inactiveForeground"))
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear Search")
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.init(id: "input.background"), in: RoundedRectangle(cornerRadius: cornerRadius ?? 10, style: .continuous))
    }
}
