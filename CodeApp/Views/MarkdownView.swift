//
//  markdown.swift
//  Code App
//
//  Created by Ken Chung on 6/12/2020.
//

import MarkdownView
import MessageUI
import SwiftUI
import UIKit

struct SimpleMarkDownView: UIViewRepresentable {

    var text: String

    func updateUIView(_ uiView: MarkdownView, context: Context) {
        uiView.changeBackgroundColor(color: UIColor(id: "editor.background"))
    }

    func makeUIView(context: Context) -> MarkdownView {
        let md = MarkdownView()
        md.load(markdown: text, backgroundColor: UIColor(id: "editor.background"))
        md.onTouchLink = { request in
            guard let url = request.url else { return false }
            UIApplication.shared.open(url)
            return false
        }
        return md
    }
}

struct ChangeLogView: View {
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            SimpleMarkDownView(text: NSLocalizedString("Changelog.message", comment: ""))
                .navigationBarTitle("Release Notes")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Done")
                            .foregroundColor(.blue)
                            .font(.body)
                    }

                }
        }
    }
}

private struct WelcomeRecentFolder: Identifiable {
    let id: Int
    let name: String
    let path: String
    let url: URL
}

private struct WelcomeAction: Identifiable {
    let id: String
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    let systemImage: String
    let isPrimary: Bool
    let action: () -> Void
}

struct WelcomeView: View {
    @EnvironmentObject var App: MainApp
    @SceneStorage("activitybar.selected.item") private var activeItemId: String = DefaultUIState.ACTIVITYBAR_SELECTED_ITEM
    @SceneStorage("sidebar.visible") private var isSideBarVisible: Bool = DefaultUIState.SIDEBAR_VISIBLE
    @SceneStorage("panel.visible") private var isPanelVisible: Bool = DefaultUIState.PANEL_IS_VISIBLE
    @SceneStorage("panel.focusedId") private var currentPanelId: String = DefaultUIState.PANEL_FOCUSED_ID
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let onCreateNewFile: () -> Void
    let onSelectFolderAsWorkspaceStorage: (URL) -> Void
    let onSelectFolder: () -> Void
    let onSelectFile: () -> Void
    let onNavigateToCloneSection: () -> Void

    private var recentFolders: [WelcomeRecentFolder] {
        guard let data = UserDefaults.standard.value(forKey: "recentFolder") as? [Data] else {
            return []
        }

        return data.indices.reversed().compactMap { index in
            var isStale = false
            guard let url = try? URL(resolvingBookmarkData: data[index], bookmarkDataIsStale: &isStale) else {
                return nil
            }

            return WelcomeRecentFolder(
                id: index,
                name: url.lastPathComponent.isEmpty ? url.path : url.lastPathComponent,
                path: url.deletingLastPathComponent().path,
                url: url
            )
        }
    }

    private var actions: [WelcomeAction] {
        [
            WelcomeAction(
                id: "open-folder",
                title: "Open Folder",
                subtitle: "Pick the project folder you want to work in.",
                systemImage: "folder.badge.gearshape",
                isPrimary: true,
                action: onSelectFolder
            ),
            WelcomeAction(
                id: "clone",
                title: "Clone Repository",
                subtitle: "Search GitHub or paste a Git URL.",
                systemImage: "arrow.down.doc.fill",
                isPrimary: false,
                action: showClonePanel
            ),
            WelcomeAction(
                id: "new-file",
                title: "New File",
                subtitle: "Create a file in the current workspace.",
                systemImage: "doc.badge.plus",
                isPrimary: false,
                action: onCreateNewFile
            ),
            WelcomeAction(
                id: "open-file",
                title: "Open File",
                subtitle: "Open a single file from Files.",
                systemImage: "doc.text.magnifyingglass",
                isPrimary: false,
                action: onSelectFile
            ),
            WelcomeAction(
                id: "terminal",
                title: "Terminal",
                subtitle: "Run commands in the local workspace.",
                systemImage: "terminal",
                isPrimary: false,
                action: showTerminal
            ),
        ]
    }

    private var gridColumns: [GridItem] {
        let minWidth: CGFloat = dynamicTypeSize.isAccessibilitySize ? 260 : 220
        return [GridItem(.adaptive(minimum: minWidth), spacing: 12)]
    }

    private var workspaceTitle: String {
        App.workSpaceStorage.currentDirectory.name.isEmpty ? "Workspace" : App.workSpaceStorage.currentDirectory.name
    }

    private var workspaceDetail: String {
        URL(string: App.workSpaceStorage.currentDirectory.url)?.path ?? App.workSpaceStorage.currentDirectory.url
    }

    private var hasGitRepository: Bool {
        !App.branch.isEmpty
    }

    private func showClonePanel() {
        activeItemId = "SOURCE_CONTROL"
        isSideBarVisible = true
        onNavigateToCloneSection()
    }

    private func showTerminal() {
        currentPanelId = "TERMINAL"
        isPanelVisible = true
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header
                actionGrid
                workspaceSection
                recentSection
            }
            .frame(maxWidth: 980, alignment: .leading)
            .padding(.horizontal, horizontalSizeClass == .compact ? 18 : 34)
            .padding(.vertical, horizontalSizeClass == .compact ? 22 : 34)
        }
        .background(Color(id: "editor.background").ignoresSafeArea())
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 14) {
                Image(systemName: "chevron.left.forwardslash.chevron.right")
                    .font(.system(size: 23, weight: .semibold))
                    .foregroundColor(Color(id: "activityBar.foreground"))
                    .frame(width: 46, height: 46)
                    .background(Color(id: "button.background").opacity(0.40), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text("App Cøde")
                        .font(.system(.largeTitle, design: .rounded).weight(.bold))
                        .foregroundColor(Color("T1"))
                    Text("Local code editing, terminal, search, and Git in one workspace.")
                        .font(.callout)
                        .foregroundColor(Color(id: "tab.inactiveForeground"))
                }
            }

            HStack(spacing: 8) {
                statusPill("Files", systemImage: "folder")
                statusPill("Editor", systemImage: "curlybraces")
                statusPill("Terminal", systemImage: "terminal")
                statusPill("Git", systemImage: "arrow.triangle.branch")
            }
        }
    }

    private var actionGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Start")
                .font(.headline)
                .foregroundColor(Color("T1"))

            LazyVGrid(columns: gridColumns, alignment: .leading, spacing: 12) {
                ForEach(actions) { action in
                    Button(action: action.action) {
                        WelcomeActionCard(action: action)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(action.title)
                    .accessibilityHint(action.subtitle)
                }
            }
        }
    }

    private var workspaceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "externaldrive")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(id: "activityBar.foreground"))
                    .frame(width: 34, height: 34)
                    .background(Color(id: "button.background").opacity(0.30), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(workspaceTitle)
                        .font(.headline)
                        .foregroundColor(Color("T1"))
                        .lineLimit(1)
                    Text(workspaceDetail)
                        .font(.caption)
                        .foregroundColor(Color(id: "tab.inactiveForeground"))
                        .lineLimit(2)
                }

                Spacer(minLength: 0)
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: dynamicTypeSize.isAccessibilitySize ? 220 : 170), spacing: 10)], spacing: 10) {
                workspaceMetric("Editor", value: App.stateManager.isMonacoEditorInitialized ? "Ready" : "Loading", systemImage: "curlybraces", isGood: App.stateManager.isMonacoEditorInitialized)
                workspaceMetric("Terminal", value: "Ready", systemImage: "terminal", isGood: true)
                workspaceMetric("Git", value: hasGitRepository ? App.branch : "Open or clone", systemImage: "arrow.triangle.branch", isGood: hasGitRepository)
                workspaceMetric("Changes", value: App.gitTracks.isEmpty ? "Clean" : "\(App.gitTracks.count) files", systemImage: "tray.full", isGood: App.gitTracks.isEmpty)
            }
        }
        .padding(16)
        .background(Color(id: "sideBar.background").opacity(0.56), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .appCodeGlassPanel(cornerRadius: 14, interactive: false)
    }

    private func workspaceMetric(_ title: LocalizedStringKey, value: String, systemImage: String, isGood: Bool) -> some View {
        HStack(spacing: 9) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(isGood ? Color.green : Color.orange)
                .frame(width: 26, height: 26)
                .background(Color(id: "button.background").opacity(0.25), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(Color(id: "tab.inactiveForeground"))
                Text(value)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(Color("T1"))
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .background(Color(id: "editor.background").opacity(0.35), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    @ViewBuilder
    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recent Workspaces")
                .font(.headline)
                .foregroundColor(Color("T1"))

            if recentFolders.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "folder")
                        .foregroundColor(Color(id: "tab.inactiveForeground"))
                    Text("Opened folders will appear here.")
                        .font(.callout)
                        .foregroundColor(Color(id: "tab.inactiveForeground"))
                    Spacer(minLength: 0)
                }
                .padding(14)
                .background(Color(id: "sideBar.background").opacity(0.58), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            } else {
                VStack(spacing: 8) {
                    ForEach(recentFolders.prefix(6)) { folder in
                        Button {
                            onSelectFolderAsWorkspaceStorage(folder.url)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "folder.fill")
                                    .foregroundColor(Color(id: "activityBar.foreground"))
                                    .frame(width: 26)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(folder.name)
                                        .font(.body.weight(.semibold))
                                        .foregroundColor(Color("T1"))
                                        .lineLimit(1)
                                    Text(folder.path)
                                        .font(.caption)
                                        .foregroundColor(Color(id: "tab.inactiveForeground"))
                                        .lineLimit(1)
                                }
                                Spacer(minLength: 0)
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(Color(id: "tab.inactiveForeground"))
                            }
                            .padding(13)
                            .background(Color(id: "sideBar.background").opacity(0.58), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func statusPill(_ title: LocalizedStringKey, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .foregroundColor(Color("T1"))
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(Color(id: "sideBar.background").opacity(0.62), in: Capsule())
    }
}

private struct WelcomeActionCard: View {
    let action: WelcomeAction

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: action.systemImage)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(action.isPrimary ? Color.white : Color(id: "activityBar.foreground"))
                .frame(width: 36, height: 36)
                .background(action.isPrimary ? Color.accentColor : Color(id: "button.background").opacity(0.35), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(action.title)
                    .font(.headline)
                    .foregroundColor(Color("T1"))
                    .lineLimit(1)
                Text(action.subtitle)
                    .font(.caption)
                    .foregroundColor(Color(id: "tab.inactiveForeground"))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 78, alignment: .topLeading)
        .padding(14)
        .background(Color(id: "sideBar.background").opacity(action.isPrimary ? 0.70 : 0.52), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(alignment: .leading) {
            if action.isPrimary {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(Color.accentColor)
                    .frame(width: 3)
                    .padding(.vertical, 12)
            }
        }
        .appCodeGlassPanel(cornerRadius: 12, interactive: true)
    }
}
