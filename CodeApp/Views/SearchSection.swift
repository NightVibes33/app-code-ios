//
//  SearchSection.swift
//  Code
//
//  Created by Ken Chung on 14/4/2022.
//

import SwiftUI

struct SearchSection: View {
    @EnvironmentObject var App: MainApp
    @FocusState private var searchBarFocused: Bool

    let onSearch: () -> Void
    let onClearSearchResults: () -> Void

    var body: some View {
        Section(
            header:
                Text("Search", comment: "")
                .foregroundColor(Color(id: "sideBarSectionHeader.foreground"))
        ) {
            VStack(alignment: .leading, spacing: 10) {
                SearchBar(
                    text: $App.textSearchManager.searchTerm,
                    searchAction: onSearch,
                    clearAction: onClearSearchResults,
                    placeholder: NSLocalizedString("Search", comment: ""), cornerRadius: 10
                )
                .focused($searchBarFocused)

                HStack(spacing: 8) {
                    SearchFilterField(title: "Include", placeholder: "*.swift", text: $App.textSearchManager.includePattern)
                    SearchFilterField(title: "Exclude", placeholder: "node_modules,.git", text: $App.textSearchManager.excludePattern)
                }

                HStack(spacing: 8) {
                    if App.textSearchManager.isSearching {
                        SearchActionPill(title: "Cancel", systemImage: "xmark.circle") {
                            App.textSearchManager.cancelSearch()
                        }
                    }
                    SearchActionPill(title: "Swift", systemImage: "swift") {
                        App.textSearchManager.includePattern = "*.swift"
                        onSearch()
                    }
                    SearchActionPill(title: "All Files", systemImage: "doc.text") {
                        App.textSearchManager.includePattern = ""
                        onSearch()
                    }
                    Spacer(minLength: 0)
                }
            }
        }.onAppear {
            if App.textSearchManager.results.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    searchBarFocused = true
                }
            }
        }

    }
}


private struct SearchFilterField: View {
    let title: LocalizedStringKey
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundColor(Color(id: "tab.inactiveForeground"))
            TextField(placeholder, text: $text)
                .font(.caption)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .padding(.horizontal, 8)
                .padding(.vertical, 7)
                .background(Color(id: "input.background"), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }
}

private struct SearchActionPill: View {
    let title: LocalizedStringKey
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundColor(Color("T1"))
                .padding(.horizontal, 9)
                .padding(.vertical, 6)
                .background(Color(id: "button.background").opacity(0.30), in: Capsule())
        }
        .buttonStyle(.plain)
    }
}
