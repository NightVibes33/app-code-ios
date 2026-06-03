//
//  GitHubSearchView.swift
//  Code
//
//  Created by Ken Chung on 12/4/2022.
//

import SwiftUI

struct GitHubSearchView: View {

    @EnvironmentObject var App: MainApp

    let onClone: (String) async throws -> Void
    let onTap: (String) -> Void

    var body: some View {
        Group {
            VStack(alignment: .leading, spacing: 9) {
                Label("Search GitHub", systemImage: "magnifyingglass")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(Color(id: "tab.inactiveForeground"))

                SearchBar(
                    text: $App.searchManager.searchTerm,
                    searchAction: { App.searchManager.search() }, placeholder: "GitHub",
                    cornerRadius: 13)
            }
            .padding(.top, 4)

            if App.searchManager.isSearching {
                AppCodeSkeletonRows(count: 3)
                    .padding(.vertical, 4)
            } else if !App.searchManager.searchTerm.isEmpty && App.searchManager.searchResultItems.isEmpty {
                DescriptionText("Press return to search repositories.")
                    .padding(.vertical, 4)
            }

            ForEach(App.searchManager.searchResultItems, id: \.html_url) { item in
                GitHubSearchResultCell(item: item, onClone: onClone, onTap: onTap)
            }
            .listRowBackground(Color.init(id: "sideBar.background"))
        }
        .onChange(of: App.searchManager.searchTerm) { _ in
            App.searchManager.searchDebounced()
        }
    }
}

struct GitHubSearchResultCell: View {

    let item: GitHubSearchManager.item

    let onClone: (String) async throws -> Void
    let onTap: (String) -> Void

    private var metadata: String {
        if let language = item.language, !language.isEmpty {
            return "\(language)  •  \(humanReadableByteCount(bytes: item.size * 1024))"
        }
        return humanReadableByteCount(bytes: item.size * 1024)
    }

    private func reportRepository() {
        let url = URL(
            string:
                "https://support.github.com/contact/report-abuse?category=report-abuse&report=other&report_type=unspecified"
        )!
        UIApplication.shared.open(url)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 9) {
                RemoteImage(url: item.owner.avatar_url)
                    .frame(width: 28, height: 28)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 1) {
                    Text(item.owner.login)
                        .font(.caption)
                        .foregroundColor(Color(id: "tab.inactiveForeground"))
                    Text(item.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Color.init("T1"))
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                Button(action: reportRepository) {
                    Image(systemName: "hand.raised")
                        .font(.system(.caption, weight: .semibold))
                        .foregroundColor(Color(id: "tab.inactiveForeground"))
                        .frame(width: 28, height: 28)
                        .background(Color(id: "button.background").opacity(0.26), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Report Repository")
            }

            if let description = item.description, !description.isEmpty {
                Text(description)
                    .font(.caption)
                    .foregroundColor(Color.init("T1"))
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 10) {
                Label("\(item.stargazers_count)", systemImage: "star.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(Color(id: "tab.inactiveForeground"))

                Text(metadata)
                    .font(.caption)
                    .foregroundColor(Color(id: "tab.inactiveForeground"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer(minLength: 8)

                CloneButton(item: item, onClone: onClone)
            }
        }
        .padding(12)
        .background(Color(id: "sideBar.background").opacity(0.58), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .appCodeGlassPanel(cornerRadius: 16, interactive: true)
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onTapGesture {
            onTap(item.html_url)
        }
    }
}

private struct CloneButton: View {
    @EnvironmentObject var App: MainApp

    let item: GitHubSearchManager.item
    let onClone: (String) async throws -> Void

    var body: some View {
        Button {
            Task {
                do {
                    try await onClone(item.clone_url)
                } catch {
                    await MainActor.run {
                        App.notificationManager.showErrorMessage(error.localizedDescription)
                    }
                }
            }
        } label: {
            Label("source_control.clone", systemImage: "arrow.down")
                .labelStyle(.titleAndIcon)
                .foregroundColor(.white)
                .lineLimit(1)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.init(id: "button.background"), in: Capsule())
        }
        .buttonStyle(.plain)
    }
}
