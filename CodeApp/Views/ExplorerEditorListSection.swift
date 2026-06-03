//
//  ExplorerEditorsSection.swift
//  Code
//
//  Created by Ken Chung on 12/11/2022.
//

import SwiftUI

struct ExplorerEditorListSection: View {

    @EnvironmentObject var App: MainApp

    let onOpenNewFile: () -> Void
    let onPickNewDirectory: () -> Void

    var body: some View {
        Section(
            header:
                Text("Open Editors")
                .foregroundColor(Color(id: "sideBarSectionHeader.foreground"))
        ) {
            if App.editors.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "folder.badge.gearshape")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(Color(id: "activityBar.foreground"))
                            .frame(width: 38, height: 38)
                            .background(Color(id: "button.background").opacity(0.34), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Start a Workspace")
                                .font(.headline)
                                .foregroundColor(Color("T1"))
                            Text("Create a file, add a folder, or switch projects.")
                                .font(.caption)
                                .foregroundColor(Color(id: "tab.inactiveForeground"))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    SidebarActionButton(title: "New File", systemImage: "doc.badge.plus", isPrimary: true) {
                        onOpenNewFile()
                    }

                    SidebarActionButton(title: "New Folder", systemImage: "folder.badge.plus") {
                        Task {
                            guard let url = App.workSpaceStorage.currentDirectory._url else { return }
                            try await App.createFolder(at: url)
                        }
                    }

                    SidebarActionButton(title: "common.open_folder", systemImage: "folder") {
                        onPickNewDirectory()
                    }
                }
                .padding(14)
                .background(Color(id: "sideBar.background").opacity(0.58), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .appCodeGlassPanel(cornerRadius: 18, interactive: false)
                .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 8, trailing: 8))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }

            ForEach(App.editors) { editor in
                EditorCell(editor: editor)
                    .frame(height: 16)
                    .listRowBackground(
                        editor == App.activeEditor
                            ? Color.init(id: "list.inactiveSelectionBackground")
                                .cornerRadius(10.0)
                            : Color.clear.cornerRadius(10.0)
                    )
                    .listRowSeparator(.hidden)
            }
        }
    }
}

private struct EditorCell: View {

    @EnvironmentObject var App: MainApp
    @Environment(\.colorScheme) var colorScheme: ColorScheme

    var editor: EditorInstance
    var editorURL: URL? {
        (editor as? EditorInstanceWithURL)?.url
    }

    func onOpenEditor() {
        App.setActiveEditor(editor: editor)
    }

    func onOpenInFilesApp() {
        guard let editorURL else { return }
        openSharedFilesApp(
            urlString: editorURL.deletingLastPathComponent().absoluteString
        )
    }

    func onCopyRelativePath() {
        guard let editorURL else { return }
        guard let baseURL = URL(string: App.workSpaceStorage.currentDirectory.url) else {
            return
        }
        let pasteboard = UIPasteboard.general
        pasteboard.string = editorURL.relativePath(from: baseURL)
    }

    func onTrashEditor() {
        guard let editorURL else { return }
        App.trashItem(url: editorURL)
    }

    var body: some View {
        Button(action: onOpenEditor) {
            ZStack {
                HStack {
                    FileIcon(url: editor.title, iconSize: 14)

                    if let editorURL,
                        let status = App.gitTracks[editorURL.standardizedFileURL]
                    {
                        FileDisplayName(gitStatus: status, name: editor.title)
                    } else {
                        FileDisplayName(gitStatus: nil, name: editor.title)
                    }

                }.padding(5)
            }
        }
        .contextMenu {
            if editorURL != nil {
                Button(action: onOpenInFilesApp) {
                    Text("Show in Files App")
                    Image(systemName: "folder")
                }

                Button(action: onCopyRelativePath) {
                    Text("Copy Relative Path")
                    Image(systemName: "link")
                }

                Button(
                    role: .destructive, action: onTrashEditor,
                    label: {
                        Text("Delete")
                        Image(systemName: "trash")
                    })
            }
        }
    }
}
