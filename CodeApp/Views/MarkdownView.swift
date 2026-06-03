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
                id: "new-file",
                title: "New File",
                subtitle: "Start a blank file in this workspace.",
                systemImage: "doc.badge.plus",
                isPrimary: true,
                action: onCreateNewFile
            ),
            WelcomeAction(
                id: "open-folder",
                title: "Open Folder",
                subtitle: "Switch to another local workspace.",
                systemImage: "folder.badge.gearshape",
                isPrimary: false,
                action: onSelectFolder
            ),
            WelcomeAction(
                id: "open-file",
                title: "Open File",
                subtitle: "Pick a single file from Files.",
                systemImage: "doc.text.magnifyingglass",
                isPrimary: false,
                action: onSelectFile
            ),
            WelcomeAction(
                id: "clone",
                title: "Clone Repo",
                subtitle: "Open Source Control for GitHub or SSH.",
                systemImage: "arrow.down.doc.fill",
                isPrimary: false,
                action: showClonePanel
            ),
        ]
    }

    private var gridColumns: [GridItem] {
        let minWidth: CGFloat = dynamicTypeSize.isAccessibilitySize ? 240 : 170
        return [GridItem(.adaptive(minimum: minWidth), spacing: 12)]
    }

    private func showClonePanel() {
        activeItemId = "SOURCE_CONTROL"
        isSideBarVisible = true
        onNavigateToCloneSection()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                actionGrid
                projectHealthSection
                recentSection
            }
            .frame(maxWidth: 920, alignment: .leading)
            .padding(.horizontal, horizontalSizeClass == .compact ? 20 : 40)
            .padding(.vertical, horizontalSizeClass == .compact ? 24 : 42)
        }
        .background(welcomeBackground)
    }

    private var welcomeBackground: some View {
        ZStack {
            Color(id: "editor.background")
            LinearGradient(
                colors: [
                    Color(id: "button.background").opacity(0.28),
                    Color(id: "editor.background").opacity(0.92),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .ignoresSafeArea()
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                Image(systemName: "chevron.left.forwardslash.chevron.right")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(Color(id: "activityBar.foreground"))
                    .frame(width: 54, height: 54)
                    .background(Color(id: "button.background").opacity(0.32), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .appCodeGlassPanel(cornerRadius: 18)

                VStack(alignment: .leading, spacing: 3) {
                    Text("App Code")
                        .font(.system(.largeTitle, design: .rounded).weight(.bold))
                        .foregroundColor(Color("T1"))
                    Text("Build, edit, run, and ship from one local workspace.")
                        .font(.callout)
                        .foregroundColor(Color(id: "tab.inactiveForeground"))
                }
            }

            HStack(spacing: 10) {
                statusPill("iOS 26", systemImage: "iphone")
                statusPill("Local-first", systemImage: "externaldrive")
                statusPill("SSH ready", systemImage: "network")
            }
        }
    }

    private var actionGrid: some View {
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

    private var workspaceTitle: String {
        App.workSpaceStorage.currentDirectory.name.isEmpty ? "Workspace" : App.workSpaceStorage.currentDirectory.name
    }

    private var workspaceDetail: String {
        URL(string: App.workSpaceStorage.currentDirectory.url)?.path ?? App.workSpaceStorage.currentDirectory.url
    }

    private var debugInfo: String {
        [
            "App Code Feedback",
            "Workspace: \(workspaceDetail)",
            "Branch: \(App.branch.isEmpty ? "No Git branch" : App.branch)",
            "Changes: \(App.gitTracks.count)",
            "Terminals: \(App.terminalManager.terminals.count)",
            "Editor ready: \(App.stateManager.isMonacoEditorInitialized)",
            "Language service: \(App.stateManager.isSystemExtensionsInitialized)",
            "Remote workspace: \(App.workSpaceStorage.remoteConnected)",
            "Notifications: \(App.notificationManager.activeNotificationCount)",
        ].joined(separator: "\n")
    }

    private func copyDebugInfo() {
        UIPasteboard.general.string = debugInfo + "\n\n" + App.notificationManager.debugSummary()
        App.notificationManager.showInformationMessage("Debug info copied")
    }

    private func sendFeedback() {
        copyDebugInfo()
        let subject = "App Code Feedback".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "App%20Code%20Feedback"
        let body = debugInfo.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "mailto:?subject=\(subject)&body=\(body)") {
            UIApplication.shared.open(url)
        }
    }

    private var projectHealthSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Project Health", systemImage: "waveform.path.ecg.rectangle")
                        .font(.headline)
                        .foregroundColor(Color("T1"))
                    Text(workspaceTitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Color("T1"))
                        .lineLimit(1)
                    Text(workspaceDetail)
                        .font(.caption)
                        .foregroundColor(Color(id: "tab.inactiveForeground"))
                        .lineLimit(2)
                }
                Spacer(minLength: 0)
                HStack(spacing: 8) {
                    Button(action: sendFeedback) {
                        Label("Feedback", systemImage: "paperplane")
                    }
                    Button(action: copyDebugInfo) {
                        Label("Debug", systemImage: "doc.on.doc")
                    }
                }
                .buttonStyle(.bordered)
                .labelStyle(.titleAndIcon)
                .font(.caption.weight(.semibold))
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: dynamicTypeSize.isAccessibilitySize ? 210 : 148), spacing: 10)], spacing: 10) {
                healthTile("Branch", value: App.branch.isEmpty ? "No Git" : App.branch, systemImage: "point.topleft.down.curvedto.point.bottomright.up", isGood: !App.branch.isEmpty)
                healthTile("Changes", value: App.gitTracks.isEmpty ? "Clean" : "\(App.gitTracks.count) files", systemImage: "tray.full", isGood: App.gitTracks.isEmpty)
                healthTile("Terminals", value: "\(App.terminalManager.terminals.count) active", systemImage: "terminal", isGood: App.terminalManager.terminals.count > 0)
                healthTile("Editor", value: App.stateManager.isMonacoEditorInitialized ? "Ready" : "Loading", systemImage: "curlybraces", isGood: App.stateManager.isMonacoEditorInitialized)
                healthTile("Language", value: App.stateManager.isSystemExtensionsInitialized ? "Ready" : "Deferred", systemImage: "sparkle.magnifyingglass", isGood: App.stateManager.isSystemExtensionsInitialized)
                healthTile("Mode", value: App.workSpaceStorage.remoteConnected ? "Remote" : "Local", systemImage: App.workSpaceStorage.remoteConnected ? "network" : "externaldrive", isGood: true)
            }
        }
        .padding(16)
        .background(Color(id: "sideBar.background").opacity(0.50), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .appCodeGlassPanel(cornerRadius: 18, interactive: false)
    }

    private func healthTile(_ title: LocalizedStringKey, value: String, systemImage: String, isGood: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(isGood ? Color.green : Color.orange)
                .frame(width: 28, height: 28)
                .background(Color(id: "button.background").opacity(0.24), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
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
        .background(Color(id: "editor.background").opacity(0.34), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    @ViewBuilder
    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Recent Workspaces", systemImage: "clock.arrow.circlepath")
                    .font(.headline)
                    .foregroundColor(Color("T1"))
                Spacer()
            }

            if recentFolders.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "folder")
                        .font(.title3)
                        .foregroundColor(Color(id: "tab.inactiveForeground"))
                    Text("Open a folder to pin it here for faster starts.")
                        .font(.callout)
                        .foregroundColor(Color(id: "tab.inactiveForeground"))
                    Spacer()
                }
                .padding(16)
                .background(Color(id: "sideBar.background").opacity(0.62), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .appCodeGlassPanel(cornerRadius: 16, interactive: false)
            } else {
                VStack(spacing: 8) {
                    ForEach(recentFolders.prefix(5)) { folder in
                        Button {
                            onSelectFolderAsWorkspaceStorage(folder.url)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "folder.fill")
                                    .foregroundColor(Color(id: "activityBar.foreground"))
                                    .frame(width: 28)
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
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(Color(id: "tab.inactiveForeground"))
                            }
                            .padding(14)
                            .background(Color(id: "sideBar.background").opacity(0.58), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .appCodeGlassPanel(cornerRadius: 18, interactive: false)
            }
        }
    }

    private func statusPill(_ title: LocalizedStringKey, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .foregroundColor(Color("T1"))
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Color(id: "sideBar.background").opacity(0.58), in: Capsule())
            .appCodeGlassPanel(cornerRadius: 18)
    }
}

private struct WelcomeActionCard: View {
    let action: WelcomeAction

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: action.systemImage)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(action.isPrimary ? Color.white : Color(id: "activityBar.foreground"))
                .frame(width: 44, height: 44)
                .background(action.isPrimary ? Color.accentColor : Color(id: "button.background").opacity(0.36), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

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
        .frame(maxWidth: .infinity, minHeight: 142, alignment: .topLeading)
        .padding(16)
        .background(Color(id: "sideBar.background").opacity(action.isPrimary ? 0.72 : 0.54), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .appCodeGlassPanel(cornerRadius: 18, interactive: true)
    }
}
