//
//  editor.swift
//  Code App
//
//  Created by Ken Chung on 5/12/2020.
//

import AVFoundation
import AVKit
import GameController
import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct EditorView: View {
    @EnvironmentObject var App: MainApp
    @EnvironmentObject var preivewProviderManager: EditorProviderManager
    @EnvironmentObject var stateManager: MainStateManager

    @AppStorage("editorLightTheme") var editorLightTheme: String = "Default"
    @AppStorage("editorDarkTheme") var editorDarkTheme: String = "Default"
    @AppStorage("editorFontSize") var editorTextSize: Int = 14
    @SceneStorage("sidebar.visible") var isSideBarVisible: Bool = DefaultUIState.SIDEBAR_VISIBLE

    @State var targeted: Bool = false

    func onDropURL(url: URL) {
        // TODO: Determine whether file is directory
        _ = url.startAccessingSecurityScopedResource()
        App.openFile(url: url, alwaysInNewTab: true)
    }

    var body: some View {
        HStack(spacing: 0) {
            ZStack {
                // Invisible buttons for creating keyboard shortcuts in SwiftUI
                VStack {
                    Button("New File") {
                        stateManager.showsNewFileSheet.toggle()
                    }.keyboardShortcut("n", modifiers: [.command])

                    Button("Open File") {
                        stateManager.showsFilePicker.toggle()
                    }
                    .keyboardShortcut("o", modifiers: [.command])
                    .sheet(isPresented: $stateManager.showsFilePicker) {
                        DocumentPickerView()
                    }

                    Button("Save") {
                        App.saveCurrentFile()

                    }
                    .keyboardShortcut("s", modifiers: [.command])
                    .sheet(
                        isPresented: $stateManager.showsChangeLog,
                        content: {
                            ChangeLogView()
                        })

                    Button("Close Editor") {
                        if let activeEditor = App.activeEditor {
                            App.closeEditor(editor: activeEditor)
                        }
                    }
                    .keyboardShortcut("w", modifiers: [.command])
                    .sheet(isPresented: $stateManager.showsDirectoryPicker) {
                        DirectoryPickerView(
                            type: .directory,
                            onOpen: { url in
                                App.loadFolder(url: url)
                                isSideBarVisible = true
                            })
                    }
                }.foregroundColor(.clear).font(.system(size: 1))

                Color.init(id: "editor.background")

                if !App.stateManager.isMonacoEditorInitialized {
                    EditorImplementationView(implementation: App.monacoInstance)
                        .overlay {
                            ProgressView()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(Color.init(id: "editor.background"))
                        }
                } else if let editor = App.activeEditor {
                    ZStack {

                        VStack {
                            Button("Command Palatte") {
                                Task {
                                    await App.monacoInstance._toggleCommandPalatte()
                                }
                            }
                            .keyboardShortcut("p", modifiers: [.command, .shift])

                            Button("Zoom in") {
                                if self.editorTextSize < 30 {
                                    self.editorTextSize += 1
                                    App.monacoInstance.options.fontSize += 1
                                }
                            }.keyboardShortcut("+", modifiers: [.command])

                            Button("Zoom out") {
                                if self.editorTextSize > 10 {
                                    self.editorTextSize -= 1
                                    App.monacoInstance.options.fontSize -= 1
                                }
                            }.keyboardShortcut("-", modifiers: [.command])
                        }.foregroundColor(.clear).font(.system(size: 1))

                        editor.view
                    }
                } else {
                    EditorEmptyState()
                        .environmentObject(stateManager)
                }

                VStack {
                    InfinityProgressView(enabled: App.workSpaceStorage.editorIsBusy)
                    Spacer()
                }

            }
            .onReceive(
                NotificationCenter.default.publisher(
                    for: Notification.Name("editor.focus"),
                    object: nil),
                perform: { notification in
                    guard let sceneIdentifier = notification.userInfo?["sceneIdentifier"] as? UUID,
                        sceneIdentifier != App.sceneIdentifier
                    else { return }
                    Task {
                        await App.monacoInstance.blur()
                    }
                }
            )
            .onReceive(
                NotificationCenter.default.publisher(
                    for: Notification.Name("terminal.focus"),
                    object: nil),
                perform: { notification in
                    Task {
                        await App.monacoInstance.blur()
                    }
                }
            )
            .onReceive(
                NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification),
                perform: { data in
                    guard
                        !App.alertManager.isShowingAlert,
                        let beginRect = data.userInfo?["UIKeyboardFrameBeginUserInfoKey"]
                            as? CGRect,
                        let endRect = data.userInfo?["UIKeyboardFrameEndUserInfoKey"] as? CGRect,
                        beginRect.origin.y != endRect.origin.y
                    else {
                        return
                    }

                    Task {
                        await App.saveCurrentFile()
                        if await App.monacoInstance.editorInFocus() {
                            await App.monacoInstance.blur()
                        }
                    }
                }
            )

        }.onDrop(
            of: [.url, .item], isTargeted: $targeted,
            perform: { providers in
                if let provider = providers.first {
                    if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                        _ = provider.loadObject(
                            ofClass: URL.self,
                            completionHandler: { url, err in
                                if let url {
                                    onDropURL(url: url)
                                }
                            })
                    } else {
                        provider.loadItem(forTypeIdentifier: UTType.item.identifier) {
                            data, error in
                            if let url = data as? URL {
                                onDropURL(url: url)
                            }
                        }
                    }

                }
                return true
            })

    }
}

private struct EditorEmptyAction: Identifiable {
    let id: String
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    let systemImage: String
    let isPrimary: Bool
    let action: () -> Void
}

private struct EditorEmptyState: View {
    @EnvironmentObject var stateManager: MainStateManager
    @SceneStorage("activitybar.selected.item") private var activeItemId: String = DefaultUIState.ACTIVITYBAR_SELECTED_ITEM
    @SceneStorage("sidebar.visible") private var isSideBarVisible: Bool = DefaultUIState.SIDEBAR_VISIBLE
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var actions: [EditorEmptyAction] {
        [
            EditorEmptyAction(
                id: "new-file",
                title: "New File",
                subtitle: "Create a file in the current workspace.",
                systemImage: "doc.badge.plus",
                isPrimary: true,
                action: { stateManager.showsNewFileSheet.toggle() }
            ),
            EditorEmptyAction(
                id: "open-folder",
                title: "Open Folder",
                subtitle: "Load a project folder from Files.",
                systemImage: "folder.badge.gearshape",
                isPrimary: false,
                action: { stateManager.showsDirectoryPicker.toggle() }
            ),
            EditorEmptyAction(
                id: "open-file",
                title: "Open File",
                subtitle: "Open one file without changing workspace.",
                systemImage: "doc.text.magnifyingglass",
                isPrimary: false,
                action: { stateManager.showsFilePicker.toggle() }
            ),
            EditorEmptyAction(
                id: "source-control",
                title: "Clone Repo",
                subtitle: "Jump to Source Control and clone a repo.",
                systemImage: "arrow.down.doc.fill",
                isPrimary: false,
                action: { showSourceControl() }
            ),
        ]
    }

    private var columns: [GridItem] {
        let minWidth: CGFloat = dynamicTypeSize.isAccessibilitySize ? 230 : 168
        return [GridItem(.adaptive(minimum: minWidth), spacing: 12)]
    }

    private func showSourceControl() {
        activeItemId = "SOURCE_CONTROL"
        isSideBarVisible = true
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header
                LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
                    ForEach(actions) { action in
                        Button(action: action.action) {
                            EditorEmptyActionCard(action: action)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(action.title)
                        .accessibilityHint(action.subtitle)
                    }
                }
            }
            .frame(maxWidth: 860, alignment: .leading)
            .padding(.horizontal, horizontalSizeClass == .compact ? 18 : 36)
            .padding(.vertical, horizontalSizeClass == .compact ? 28 : 44)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [
                    Color(id: "button.background").opacity(0.18),
                    Color(id: "editor.background"),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 16) {
            Image(systemName: "curlybraces.square.fill")
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(Color(id: "activityBar.foreground"))
                .frame(width: 58, height: 58)
                .background(Color(id: "sideBar.background").opacity(0.62), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .appCodeGlassPanel(cornerRadius: 18)

            VStack(alignment: .leading, spacing: 5) {
                Text("No Editor Open")
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .foregroundColor(Color("T1"))
                Text("Start with a file, workspace, or repository.")
                    .font(.callout)
                    .foregroundColor(Color(id: "tab.inactiveForeground"))
            }
        }
    }
}

private struct EditorEmptyActionCard: View {
    let action: EditorEmptyAction

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            Image(systemName: action.systemImage)
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(action.isPrimary ? Color.white : Color(id: "activityBar.foreground"))
                .frame(width: 42, height: 42)
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
        .frame(maxWidth: .infinity, minHeight: 134, alignment: .topLeading)
        .padding(15)
        .background(Color(id: "sideBar.background").opacity(action.isPrimary ? 0.70 : 0.52), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .appCodeGlassPanel(cornerRadius: 18, interactive: true)
    }
}
