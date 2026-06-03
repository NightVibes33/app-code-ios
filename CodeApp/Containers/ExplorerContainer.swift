//
//  ExplorerContainer.swift
//  Code App
//
//  Created by Ken Chung on 5/12/2020.
//

import SwiftUI
import UniformTypeIdentifiers

struct ExplorerContainer: View {

    @EnvironmentObject var App: MainApp
    @EnvironmentObject var stateManager: MainStateManager
    @EnvironmentObject var themeManager: ThemeManager

    @State var selectedURL: String = ""
    @State private var selectKeeper = Set<String>()
    @State private var editMode = EditMode.inactive
    @State private var searchString: String = ""
    @State private var searching: Bool = false

    @AppStorage("explorer.showHiddenFiles") var showHiddenFiles: Bool = false

    func onOpenNewFile() {
        stateManager.showsNewFileSheet.toggle()
    }

    func onPickNewDirectory() {
        stateManager.showsDirectoryPicker.toggle()
    }

    func openSharedFilesApp(urlString: String) {
        let sharedurl = urlString.replacingOccurrences(of: "file://", with: "shareddocuments://")
        if let furl: URL = URL(string: sharedurl) {
            UIApplication.shared.open(furl, options: [:], completionHandler: nil)
        }
    }

    func onDragCell(item: WorkSpaceStorage.FileItemRepresentable) -> NSItemProvider {
        guard let url = item._url else {
            return NSItemProvider()
        }
        if item.subFolderItems != nil {
            let itemProvider = NSItemProvider()
            itemProvider.suggestedName = url.lastPathComponent
            itemProvider.registerFileRepresentation(
                forTypeIdentifier: "public.folder", visibility: .all
            ) {
                $0(url, false, nil)
                return nil
            }
            return itemProvider
        } else {
            guard let provider = NSItemProvider(contentsOf: url) else {
                return NSItemProvider()
            }
            provider.suggestedName = url.lastPathComponent
            return provider
        }
    }

    func onDropToFolder(item: WorkSpaceStorage.FileItemRepresentable, providers: [NSItemProvider])
        -> Bool
    {
        if let provider = providers.first {
            provider.loadItem(forTypeIdentifier: UTType.item.identifier) {
                data, error in
                if let at = data as? URL,
                    let to = item._url?.appendingPathComponent(
                        at.lastPathComponent, conformingTo: .item)
                {
                    App.workSpaceStorage.copyItem(
                        at: at, to: to,
                        completionHandler: { error in
                            if let error = error {
                                App.notificationManager.showErrorMessage(
                                    error.localizedDescription)
                            }
                        })
                }
            }
        }
        return true
    }

    func scrollToActiveEditor(proxy: ScrollViewProxy) {
        if let url = (App.activeEditor as? EditorInstanceWithURL)?.url {
            proxy.scrollTo(url.absoluteString, anchor: .center)
        }
    }

    func explorerNotificationHandler(
        notification: NotificationCenter.Publisher.Output, proxy: ScrollViewProxy
    ) {
        guard
            let sceneIdentifier =
                notification.userInfo?["sceneIdentifier"] as? UUID,
            sceneIdentifier == App.sceneIdentifier
        else { return }

        if let target = notification.userInfo?["target"] as? URL {
            proxy.scrollTo(target.absoluteString, anchor: .center)
        }
    }

    func onMoveFile(
        from: WorkSpaceStorage.FileItemRepresentable, to: WorkSpaceStorage.FileItemRepresentable
    ) {
        guard let fromUrl = from._url,
            let toUrl = to._url?.appending(path: fromUrl.lastPathComponent)
        else {
            return
        }

        App.moveFile(fromUrl: fromUrl, toUrl: toUrl)
    }

    var body: some View {
        VStack(spacing: 0) {

            InfinityProgressView(enabled: App.workSpaceStorage.explorerIsBusy)

            ExplorerFileTree(
                searchString: searchString, onDrag: onDragCell,
                onMoveFile: onMoveFile
            )

            Spacer()

            VStack(spacing: 8) {
                if editMode == EditMode.inactive {
                    if searching {
                        HStack(spacing: 8) {
                            Label("Filter", systemImage: "line.horizontal.3.decrease")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(Color(id: "activityBar.foreground"))
                            TextField("Filter files", text: $searchString)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .font(.caption)
                            ExplorerToolbarButton(title: "Done", systemImage: "checkmark.circle") {
                                withAnimation { searching = false }
                            }
                        }
                        .padding(.horizontal, 8)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ExplorerToolbarButton(title: "New", systemImage: "doc.badge.plus", action: onOpenNewFile)
                                ExplorerToolbarButton(title: "Folder", systemImage: "folder.badge.plus") {
                                    Task {
                                        guard let url = App.workSpaceStorage.currentDirectory._url else { return }
                                        try await App.createFolder(at: url)
                                    }
                                }
                                if !App.workSpaceStorage.remoteConnected {
                                    ExplorerToolbarButton(title: "Open", systemImage: "folder.badge.gear", action: onPickNewDirectory)
                                }
                                ExplorerToolbarButton(title: "Filter", systemImage: "line.3.horizontal.decrease") {
                                    withAnimation { searching = true }
                                }
                                ExplorerToolbarButton(title: "Reload", systemImage: "arrow.clockwise") {
                                    App.reloadDirectory()
                                }
                            }
                            .padding(.horizontal, 8)
                        }
                    }
                } else {
                    HStack(spacing: 8) {
                        ExplorerToolbarButton(title: "Trash", systemImage: "trash", isEnabled: !selectKeeper.isEmpty) {
                            for item in Array(selectKeeper) {
                                App.trashItem(url: URL(string: item)!)
                                selectKeeper.remove(item)
                            }
                            editMode = EditMode.inactive
                        }
                        ExplorerToolbarButton(title: "Copy", systemImage: "square.on.square", isEnabled: !selectKeeper.isEmpty) {
                            for item in Array(selectKeeper) {
                                Task {
                                    try await App.duplicateItem(at: URL(string: item)!)
                                }
                            }
                            editMode = EditMode.inactive
                        }
                        ExplorerToolbarButton(title: "Done", systemImage: "checkmark.circle") {
                            withAnimation { editMode = EditMode.inactive }
                        }
                    }
                    .padding(.horizontal, 8)
                }
            }
            .padding(.vertical, 8)
            .background(Color.init(id: "activityBar.background"))
            .cornerRadius(10)
            .padding(.bottom, 15)
            .padding(.horizontal, 8)

        }
    }
}


private struct ExplorerToolbarButton: View {
    let title: LocalizedStringKey
    let systemImage: String
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundColor(isEnabled ? Color(id: "activityBar.foreground") : .gray)
                .lineLimit(1)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Color(id: "button.background").opacity(isEnabled ? 0.30 : 0.12), in: Capsule())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}
