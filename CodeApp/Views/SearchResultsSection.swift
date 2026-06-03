//
//  SearchResultsSection.swift
//  Code
//
//  Created by Ken Chung on 15/4/2022.
//

import SwiftUI

struct SearchResultsSection: View {

    @EnvironmentObject var App: MainApp

    let onTapSearchResult: (SearchResult, URL) -> Void

    private func binding(for key: String) -> Binding<Bool> {
        return .init(
            get: { App.textSearchManager.expansionStates[key, default: false] },
            set: { App.textSearchManager.expansionStates[key] = $0 })
    }

    var body: some View {
        Section(
            header:
                HStack {
                    Text("Results")
                    if !App.textSearchManager.message.isEmpty {
                        Text(" " + App.textSearchManager.message)
                    }
                }.foregroundColor(Color(id: "sideBarSectionHeader.foreground"))
        ) {
            if App.textSearchManager.isSearching {
                AppCodeSkeletonRows(count: 4)
                    .padding(.vertical, 4)
            } else if App.textSearchManager.results.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Image(systemName: App.textSearchManager.searchTerm.isEmpty ? "magnifyingglass" : "doc.text.magnifyingglass")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(Color(id: "activityBar.foreground"))
                    Text(App.textSearchManager.searchTerm.isEmpty ? "Search this workspace" : "No matches found")
                        .font(.headline)
                        .foregroundColor(Color("T1"))
                    Text(App.textSearchManager.searchTerm.isEmpty ? "Type a term above. Use Include for patterns like *.swift and Exclude for folders like node_modules,.git." : "Try a shorter term or adjust include/exclude filters.")
                        .font(.caption)
                        .foregroundColor(Color(id: "tab.inactiveForeground"))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(14)
                .background(Color(id: "sideBar.background").opacity(0.58), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .appCodeGlassPanel(cornerRadius: 18, interactive: false)
            }

            if let mainFolderUrl = URL(string: App.workSpaceStorage.currentDirectory.url) {
                ForEach(Array(App.textSearchManager.results.keys.sorted()), id: \.self) { key in
                    let fileURL = URL(fileURLWithPath: key)

                    if let result = App.textSearchManager.results[key] {
                        DisclosureGroup(
                            isExpanded: binding(for: key),
                            content: {
                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(result) { res in
                                        Button {
                                            onTapSearchResult(res, fileURL)
                                        } label: {
                                            HStack(alignment: .top, spacing: 8) {
                                                Text("\(res.line_num)")
                                                    .font(.caption.monospacedDigit())
                                                    .foregroundColor(Color(id: "tab.inactiveForeground"))
                                                    .frame(width: 36, alignment: .trailing)
                                                HighlightedText(
                                                    res.line.trimmingCharacters(in: .whitespacesAndNewlines),
                                                    matching: App.textSearchManager.searchTerm,
                                                    accentColor: Color.init(id: "list.highlightForeground")
                                                )
                                                .foregroundColor(Color.init("T1"))
                                                .font(.custom("Menlo Regular", size: 13))
                                                .lineLimit(2)
                                                Spacer(minLength: 0)
                                            }
                                            .padding(8)
                                            .background(Color(id: "button.background").opacity(0.18), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.top, 8)
                            },
                            label: {
                                HStack(spacing: 10) {
                                    FileIcon(url: key, iconSize: 14)
                                    VStack(alignment: .leading, spacing: 2) {
                                        HStack(spacing: 6) {
                                            Text(fileURL.lastPathComponent)
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundColor(Color.init("T1"))
                                                .lineLimit(1)
                                            Text("\(result.count)")
                                                .font(.caption.weight(.bold))
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 7)
                                                .padding(.vertical, 3)
                                                .background(Color(id: "button.background"), in: Capsule())
                                        }
                                        if let path = fileURL.deletingLastPathComponent().relativePath(from: mainFolderUrl), !path.isEmpty {
                                            Text(path)
                                                .foregroundColor(Color(id: "tab.inactiveForeground"))
                                                .font(.caption2)
                                                .lineLimit(1)
                                        }
                                    }
                                }
                                .padding(10)
                                .background(Color(id: "sideBar.background").opacity(0.58), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            })
                    }
                }
            }
        }
    }

}
