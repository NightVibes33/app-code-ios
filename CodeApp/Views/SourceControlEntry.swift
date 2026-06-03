//
//  gitCell.swift
//  Code App
//
//  Created by Ken Chung on 8/12/2020.
//

import SwiftGit2
import SwiftUI

struct SourceControlEntry: View {
    @EnvironmentObject var App: MainApp
    @State var itemUrl: URL
    @State var isIndex: Bool

    let onUnstage: (String) throws -> Void
    let onRevert: (String, Bool) async throws -> Void
    let onStage: ([String]) throws -> Void
    let onShowChangesInDiffEditor: (String) throws -> Void

    private var status: Diff.Status? {
        isIndex ? App.indexedResources[itemUrl] : App.workingResources[itemUrl]
    }

    private var canOpenDiff: Bool {
        guard let status else { return false }
        return !isIndex && status != .workTreeNew
    }

    private var relativePath: String {
        guard let workspaceURL = URL(string: App.workSpaceStorage.currentDirectory.url) else {
            return itemUrl.deletingLastPathComponent().lastPathComponent
        }
        let workspacePath = workspaceURL.path
        let filePath = itemUrl.deletingLastPathComponent().path
        guard filePath.hasPrefix(workspacePath) else {
            return filePath
        }
        let relative = filePath.dropFirst(workspacePath.count).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return relative.isEmpty ? "Workspace root" : relative
    }

    private func openDiffIfPossible() {
        guard canOpenDiff else { return }
        do {
            try onShowChangesInDiffEditor(itemUrl.absoluteString)
        } catch {
            App.notificationManager.showErrorMessage(error.localizedDescription)
        }
    }

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            FileIcon(url: itemUrl.absoluteString, iconSize: 18)
                .frame(width: 26)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(itemUrl.lastPathComponent)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Color("T1"))
                        .lineLimit(1)

                    if let status {
                        Text(status.symbol)
                            .font(.caption2.weight(.bold))
                            .foregroundColor(status.backgroundColor)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(status.backgroundColor.opacity(0.15), in: Capsule())
                    }
                }

                Text(relativePath)
                    .font(.caption2)
                    .foregroundColor(Color(id: "tab.inactiveForeground"))
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            if let status {
                Controls(
                    status: status,
                    itemUrl: itemUrl,
                    canOpenDiff: canOpenDiff,
                    onUnstage: onUnstage,
                    onRevert: onRevert,
                    onStage: onStage,
                    onDiff: openDiffIfPossible
                )
            }
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
        .background(Color(id: "sideBar.background").opacity(0.30), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .onTapGesture(perform: openDiffIfPossible)
        .if(itemUrl == (App.activeEditor as? EditorInstanceWithURL)?.url) {
            $0.listRowBackground(
                Color.init(id: "list.inactiveSelectionBackground").cornerRadius(10.0))
        }
    }
}

private struct Controls: View {
    @EnvironmentObject var App: MainApp

    let status: Diff.Status
    let itemUrl: URL
    let canOpenDiff: Bool
    let onUnstage: (String) throws -> Void
    let onRevert: (String, Bool) async throws -> Void
    let onStage: ([String]) throws -> Void
    let onDiff: () -> Void

    private func unstage() {
        do {
            try onUnstage(itemUrl.absoluteString)
        } catch {
            App.notificationManager.showErrorMessage(error.localizedDescription)
        }
    }

    private func stage() {
        do {
            try onStage([itemUrl.absoluteString])
        } catch {
            App.notificationManager.showErrorMessage(error.localizedDescription)
        }
    }

    private func revert() {
        Task {
            do {
                try await onRevert(itemUrl.absoluteString, false)
            } catch {
                App.notificationManager.showErrorMessage(error.localizedDescription)
            }
        }
    }

    var body: some View {
        HStack(spacing: 6) {
            if canOpenDiff {
                SourceControlActionButton(title: "Diff", systemImage: "doc.text.magnifyingglass", action: onDiff)
            }

            switch status {
            case .indexModified, .indexNew, .indexDeleted:
                SourceControlActionButton(title: "Unstage", systemImage: "minus", action: unstage)
            case .workTreeModified, .workTreeDeleted:
                SourceControlActionButton(title: "Revert", systemImage: "arrow.uturn.backward", action: revert)
                SourceControlActionButton(title: "Stage", systemImage: "plus", action: stage)
            case .workTreeNew:
                SourceControlActionButton(title: "Stage", systemImage: "plus", action: stage)
            case .conflicted:
                SourceControlActionButton(title: "Resolve", systemImage: "exclamationmark.triangle", action: onDiff)
                    .disabled(!canOpenDiff)
            default:
                EmptyView()
            }
        }
    }
}

private struct SourceControlActionButton: View {
    let title: LocalizedStringKey
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .labelStyle(.iconOnly)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color("T1"))
                .frame(width: 28, height: 28)
                .background(Color(id: "button.background").opacity(0.32), in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

extension Diff.Status {
    var backgroundColor: Color {
        switch self {
        case .workTreeModified, .indexModified:
            return Color.init("git.modified")
        case .workTreeNew:
            return Color.init("git.untracked")
        case .workTreeDeleted, .indexDeleted, .conflicted:
            return Color.init("git.deleted")
        case .indexNew:
            return Color.init("git.added")
        default:
            return Color.init(id: "list.inactiveSelectionForeground")
        }
    }

    var symbol: String {
        switch self {
        case .workTreeModified, .indexModified:
            return "M"
        case .workTreeNew:
            return "U"
        case .workTreeDeleted, .indexDeleted:
            return "D"
        case .indexNew:
            return "A"
        case .conflicted:
            return "C"
        default:
            return "X"
        }
    }
}
