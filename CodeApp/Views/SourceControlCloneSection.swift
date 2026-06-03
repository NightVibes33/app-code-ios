//
//  SourceControlCloneSection.swift
//  Code
//
//  Created by Ken Chung on 12/4/2022.
//

import SwiftUI
import UIKit

struct SourceControlCloneSection: View {

    @EnvironmentObject var App: MainApp
    @State private var gitURL: String = ""
    @State private var isCloning = false

    let onClone: (String) async throws -> Void
    let onTapResult: (String) -> Void

    private var trimmedGitURL: String {
        gitURL.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canClone: Bool {
        !trimmedGitURL.isEmpty && !isCloning && !App.stateManager.gitServiceIsBusy
    }

    private func pasteGitURL() {
        guard
            let clipboard = UIPasteboard.general.string?.trimmingCharacters(
                in: .whitespacesAndNewlines),
            !clipboard.isEmpty
        else {
            App.notificationManager.showWarningMessage("Clipboard is empty.")
            return
        }
        gitURL = clipboard
    }

    private func cloneFromInput() {
        let url = trimmedGitURL
        guard !url.isEmpty else {
            App.notificationManager.showWarningMessage("Enter a repository URL first.")
            return
        }
        guard !isCloning && !App.stateManager.gitServiceIsBusy else {
            App.notificationManager.showWarningMessage("Source Control is busy.")
            return
        }

        isCloning = true
        Task {
            do {
                try await onClone(url)
                await MainActor.run {
                    gitURL = ""
                }
            } catch {
                await MainActor.run {
                    App.notificationManager.showErrorMessage(error.localizedDescription)
                }
            }
            await MainActor.run {
                isCloning = false
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
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                    Text(App.searchManager.errorMessage).font(
                        .system(size: 12, weight: .light))
                }.foregroundColor(.gray)
            }

            HStack {
                Image(systemName: "link")
                    .foregroundColor(.gray)
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

                Spacer()

            }.padding(7)
                .background(Color.init(id: "input.background"))
                .cornerRadius(10)

            HStack(spacing: 8) {
                Button(action: cloneFromInput) {
                    HStack {
                        Spacer()
                        if isCloning || App.stateManager.gitServiceIsBusy {
                            ProgressView()
                                .progressViewStyle(.circular)
                        }
                        Text("source_control.clone")
                            .font(.subheadline)
                            .lineLimit(1)
                        Spacer()
                    }
                    .foregroundColor(.white)
                    .padding(6)
                    .background(canClone ? Color.accentColor : Color(id: "button.background"))
                    .cornerRadius(10)
                }
                .disabled(!canClone)

                Button(action: pasteGitURL) {
                    Label("Paste", systemImage: "doc.on.clipboard")
                        .font(.subheadline)
                        .lineLimit(1)
                        .padding(6)
                        .background(Color(id: "button.background"))
                        .cornerRadius(10)
                }

                Button(action: { gitURL = "" }) {
                    Label("Clear", systemImage: "xmark.circle")
                        .font(.subheadline)
                        .lineLimit(1)
                        .padding(6)
                        .background(Color(id: "button.background"))
                        .cornerRadius(10)
                }
                .disabled(gitURL.isEmpty)
            }

            DescriptionText("Example: https://github.com/NightVibes33/app-code-ios.git")

            GitHubSearchView(onClone: onClone, onTap: onTapResult)
        }
    }
}
