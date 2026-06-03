//
//  SourceControlCloneSection.swift
//  Code
//
//  Created by Ken Chung on 12/4/2022.
//

import Foundation
import SwiftUI
import UIKit

struct SourceControlCloneSection: View {

    @EnvironmentObject var App: MainApp
    @State private var gitURL: String = ""
    @State private var destinationName: String = ""

    let onClone: (String, String?) async throws -> Void
    let onTapResult: (String) -> Void

    private var sanitizedURL: String {
        gitURL.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var sanitizedDestinationName: String {
        destinationName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var inferredRepoName: String {
        if sanitizedURL.contains("@"), let separator = sanitizedURL.firstIndex(of: ":") {
            return String(sanitizedURL[sanitizedURL.index(after: separator)...])
                .split(separator: "/")
                .last
                .map(String.init)?
                .replacingOccurrences(of: ".git", with: "") ?? "repo"
        }
        guard let url = URL(string: sanitizedURL), !url.lastPathComponent.isEmpty else {
            return "repo"
        }
        return url.deletingPathExtension().lastPathComponent
    }

    private var destinationPreview: String {
        let folder = sanitizedDestinationName.isEmpty ? inferredRepoName : sanitizedDestinationName
        return "Will clone into /\(folder)"
    }

    private var canClone: Bool {
        !sanitizedURL.isEmpty && !App.stateManager.gitServiceIsBusy
    }

    private func pasteRemoteURL() {
        guard let clipboardURL = UIPasteboard.general.string?.trimmingCharacters(in: .whitespacesAndNewlines),
            !clipboardURL.isEmpty
        else {
            App.notificationManager.showInformationMessage("Clipboard is empty.")
            return
        }
        gitURL = clipboardURL
        if destinationName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            destinationName = inferredRepoName
        }
    }

    private func cloneFromInput() {
        guard canClone else { return }
        let url = sanitizedURL
        Task {
            do {
                try await onClone(url, sanitizedDestinationName.isEmpty ? nil : sanitizedDestinationName)
                await MainActor.run {
                    gitURL = ""
                    destinationName = ""
                }
            } catch {
                await MainActor.run {
                    App.notificationManager.showErrorMessage(error.localizedDescription)
                }
            }
        }
    }

    var body: some View {
        Section(
            header:
                Text("Clone Repository")
                .foregroundColor(Color(id: "sideBarSectionHeader.foreground"))
        ) {

            if App.searchManager.errorMessage != "" {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                    Text(App.searchManager.errorMessage)
                        .font(.system(size: 12, weight: .light))
                }
                .foregroundColor(.gray)
                .padding(.vertical, 4)
            }

            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "arrow.down.doc.fill")
                        .font(.system(size: 21, weight: .semibold))
                        .foregroundColor(Color(id: "activityBar.foreground"))
                        .frame(width: 42, height: 42)
                        .background(Color(id: "button.background").opacity(0.34), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Clone from Git")
                            .font(.headline)
                            .foregroundColor(Color("T1"))
                        Text("Paste a GitHub HTTPS URL or SSH remote and clone it into this workspace.")
                            .font(.caption)
                            .foregroundColor(Color(id: "tab.inactiveForeground"))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                HStack(spacing: 8) {
                    Image(systemName: "link")
                        .foregroundColor(Color(id: "tab.inactiveForeground"))
                        .font(.subheadline)

                    TextField(
                        "URL (HTTPS/SSH)", text: $gitURL,
                        onCommit: cloneFromInput
                    )
                    .textContentType(.URL)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .submitLabel(.go)

                    Button(action: cloneFromInput) {
                        Image(systemName: App.stateManager.gitServiceIsBusy ? "clock" : "arrow.down")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 30, height: 30)
                            .background(canClone ? Color.accentColor : Color.gray.opacity(0.45), in: Circle())
                    }
                    .disabled(!canClone)
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clone Repository")
                }
                .padding(8)
                .background(Color.init(id: "input.background"), in: RoundedRectangle(cornerRadius: 13, style: .continuous))

                HStack(spacing: 8) {
                    Image(systemName: "folder.badge.gearshape")
                        .foregroundColor(Color(id: "tab.inactiveForeground"))
                        .font(.subheadline)

                    TextField("Destination folder", text: $destinationName)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)

                    Button("Use URL") {
                        destinationName = inferredRepoName
                    }
                    .font(.caption.weight(.semibold))
                    .buttonStyle(.plain)
                    .foregroundColor(Color(id: "activityBar.foreground"))
                }
                .padding(8)
                .background(Color.init(id: "input.background"), in: RoundedRectangle(cornerRadius: 13, style: .continuous))

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 74), spacing: 8)], alignment: .leading, spacing: 8) {
                    SourceControlClonePill(title: "HTTPS", systemImage: "lock")
                    SourceControlClonePill(title: "SSH", systemImage: "key")
                    SourceControlCloneActionPill(title: "Paste", systemImage: "doc.on.clipboard", action: pasteRemoteURL)
                    SourceControlCloneActionPill(title: "Clear", systemImage: "xmark.circle", action: {
                        gitURL = ""
                        destinationName = ""
                    })
                    .disabled(gitURL.isEmpty && destinationName.isEmpty)
                }

                DescriptionText(verbatim: destinationPreview)
                DescriptionText("Example: https://github.com/NightVibes33/app-code-ios.git")
            }
            .padding(14)
            .background(Color(id: "sideBar.background").opacity(0.58), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .appCodeGlassPanel(cornerRadius: 18, interactive: false)

            GitHubSearchView(onClone: { url in try await onClone(url, nil) }, onTap: onTapResult)
        }
    }
}

private struct SourceControlClonePill: View {
    let title: String
    let systemImage: String

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .foregroundColor(Color("T1"))
            .lineLimit(1)
            .minimumScaleFactor(0.78)
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(Color(id: "button.background").opacity(0.30), in: Capsule())
    }
}


private struct SourceControlCloneActionPill: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundColor(Color("T1"))
                .lineLimit(1)
                .minimumScaleFactor(0.78)
                .padding(.horizontal, 9)
                .padding(.vertical, 6)
                .background(Color(id: "button.background").opacity(0.42), in: Capsule())
        }
        .buttonStyle(.plain)
    }
}
