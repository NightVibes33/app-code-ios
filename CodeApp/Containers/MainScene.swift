//
//  main.swift
//  Code App
//
//  Created by Ken Chung on 5/12/2020.
//

import CoreSpotlight
import SwiftUI
import UIKit
import ios_system

struct MainScene: View {
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject var App = MainApp()

    @AppStorage("stateRestorationEnabled") var stateRestorationEnabled = true
    @SceneStorage("root.bookmark") var rootDirectoryBookmark: Data?
    @SceneStorage("openEditors.bookmarks") var openEditorsBookmarksData: Data?
    @SceneStorage("activeEditor.bookmark") var activeEditorBookmark: Data?
    @SceneStorage("activeEditor.monaco.state") var activeEditorMonacoState: String?

    func getOpenEditorsBookmarks() -> [Data] {
        guard let openEditorsBookmarksData else { return [] }
        return (try? PropertyListDecoder().decode([Data].self, from: openEditorsBookmarksData))
            ?? []
    }

    func setOpenEditorsBookmarks(_ v: [Data]) {
        openEditorsBookmarksData = try? PropertyListEncoder().encode(v)
    }

    func saveSceneState() {
        guard stateRestorationEnabled else { return }
        guard let rootDir = App.workSpaceStorage.currentDirectory._url,
            rootDir.isFileURL,
            let rootDirBookmarkData = try? rootDir.bookmarkData()
        else {
            return
        }
        rootDirectoryBookmark = rootDirBookmarkData
        setOpenEditorsBookmarks(App.editorsWithURL.compactMap { try? $0.url.bookmarkData() })

        if let activeEditor = App.activeTextEditor,
            let activeEditorBookmarkData = try? activeEditor.url.bookmarkData()
        {
            activeEditorBookmark = activeEditorBookmarkData
            Task {
                activeEditorMonacoState = await App.monacoInstance.getViewState()
            }
        } else {
            activeEditorBookmark = nil
            activeEditorMonacoState = nil
        }
    }

    func restoreSceneState() {

        var isStale = false

        guard stateRestorationEnabled else { return }
        guard let rootDirBookmark = rootDirectoryBookmark,
            let rootDir = try? URL(
                resolvingBookmarkData: rootDirBookmark, bookmarkDataIsStale: &isStale)
        else {
            return
        }
        App.loadFolder(url: rootDir)

        let editors = getOpenEditorsBookmarks().compactMap {
            try? URL(resolvingBookmarkData: $0, bookmarkDataIsStale: &isStale)
        }
        for editor in editors {
            App.openFile(url: editor, alwaysInNewTab: true)
        }

        if let activeEditorBookmark = activeEditorBookmark,
            let activeEditor = try? URL(
                resolvingBookmarkData: activeEditorBookmark, bookmarkDataIsStale: &isStale)
        {
            App.openFile(url: activeEditor)
        }

        App.monacoStateToRestore = activeEditorMonacoState
    }

    var body: some View {
        MainView()
            .environmentObject(App)
            .environmentObject(App.extensionManager)
            .environmentObject(App.stateManager)
            .environmentObject(App.alertManager)
            .environmentObject(App.safariManager)
            .environmentObject(App.directoryPickerManager)
            .environmentObject(App.createFileSheetManager)
            .environmentObject(App.authenticationRequestManager)
            .onAppear {
                restoreSceneState()
                App.extensionManager.initializeExtensions(app: App)
            }
            .onOpenURL { url in
                _ = url.startAccessingSecurityScopedResource()
                App.openFile(url: url)
            }
            .onReceive(
                NotificationCenter.default.publisher(
                    for: UIApplication.willResignActiveNotification)
            ) { _ in
                saveSceneState()
            }
            .onReceive(
                NotificationCenter.default.publisher(
                    for: Notification.Name("theme.updated"),
                    object: nil
                ),
                perform: { notification in
                    guard var theme = themeManager.currentTheme else {
                        return
                    }
                    App.monacoInstance.theme = EditorTheme(
                        dark: ThemeManager.darkTheme, light: ThemeManager.lightTheme)
                    App.terminalManager.applyThemeToAll(rawTheme: theme.dictionary)
                }
            )
    }
}


private struct CommandPaletteItem: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let systemImage: String
    let keywords: String
    let action: () -> Void
}

private struct CommandPaletteView: View {
    @EnvironmentObject var App: MainApp
    @EnvironmentObject var stateManager: MainStateManager
    @Environment(\.dismiss) private var dismiss

    @SceneStorage("activitybar.selected.item") private var activeItemId: String = DefaultUIState.ACTIVITYBAR_SELECTED_ITEM
    @SceneStorage("sidebar.visible") private var isSideBarVisible: Bool = DefaultUIState.SIDEBAR_VISIBLE
    @SceneStorage("panel.visible") private var isPanelVisible: Bool = DefaultUIState.PANEL_IS_VISIBLE
    @SceneStorage("panel.height") private var panelHeight: Double = DefaultUIState.PANEL_HEIGHT
    @SceneStorage("panel.focusedId") private var currentPanelId: String = DefaultUIState.PANEL_FOCUSED_ID

    @State private var query = ""
    @AppStorage("commandPalette.recentCommandIds") private var recentCommandIds = ""

    private var commands: [CommandPaletteItem] {
        [
            CommandPaletteItem(id: "new-file", title: "New File", subtitle: "Create a file in the current workspace.", systemImage: "doc.badge.plus", keywords: "create file new document", action: { stateManager.showsNewFileSheet = true }),
            CommandPaletteItem(id: "open-file", title: "Open File", subtitle: "Pick a single file from Files.", systemImage: "doc.text.magnifyingglass", keywords: "open file document picker", action: { stateManager.showsFilePicker = true }),
            CommandPaletteItem(id: "open-folder", title: "Open Folder", subtitle: "Switch to a workspace folder.", systemImage: "folder.badge.gearshape", keywords: "workspace folder project files", action: { stateManager.showsDirectoryPicker = true }),
            CommandPaletteItem(id: "clone", title: "Clone Repository", subtitle: "Open Source Control for GitHub or SSH clone.", systemImage: "arrow.down.doc.fill", keywords: "git github clone repository source control", action: { showSidebar("SOURCE_CONTROL") }),
            CommandPaletteItem(id: "search", title: "Search Workspace", subtitle: "Find text across the current folder.", systemImage: "magnifyingglass", keywords: "find search grep workspace", action: { showSidebar("SEARCH") }),
            CommandPaletteItem(id: "explorer", title: "Show Explorer", subtitle: "Browse files, folders, and open editors.", systemImage: "doc.text.magnifyingglass", keywords: "explorer sidebar files folders", action: { showSidebar("EXPLORER") }),
            CommandPaletteItem(id: "source-control", title: "Show Source Control", subtitle: "Review changes, commits, branches, and remotes.", systemImage: "point.topleft.down.curvedto.point.bottomright.up", keywords: "git source control commit branch push pull", action: { showSidebar("SOURCE_CONTROL") }),
            CommandPaletteItem(id: "terminal", title: "Show Terminal", subtitle: "Open the terminal panel.", systemImage: "terminal", keywords: "console terminal shell panel", action: { showPanel("TERMINAL") }),
            CommandPaletteItem(id: "new-terminal", title: "New Terminal", subtitle: "Create and focus another terminal session.", systemImage: "plus.rectangle.on.rectangle", keywords: "terminal shell new", action: { App.terminalManager.createTerminal(); showPanel("TERMINAL") }),
            CommandPaletteItem(id: "welcome", title: "Welcome Screen", subtitle: "Return to the App Code command center.", systemImage: "sparkles.rectangle.stack", keywords: "home welcome start command center", action: { App.showWelcomeMessage() }),
            CommandPaletteItem(id: "settings", title: "Settings", subtitle: "Editor, terminal, Git, remote, and appearance settings.", systemImage: "slider.horizontal.3", keywords: "preferences settings config", action: { stateManager.showsSettingsSheet = true }),
        ]
    }

    private var normalizedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private var recentCommandIdList: [String] {
        recentCommandIds.split(separator: ",").map(String.init)
    }

    private var recentCommands: [CommandPaletteItem] {
        recentCommandIdList.compactMap { id in
            commands.first { $0.id == id }
        }
    }

    private var displayedCommands: [CommandPaletteItem] {
        guard !normalizedQuery.isEmpty else { return commands }
        return commands.enumerated().compactMap { index, item -> (index: Int, score: Int, item: CommandPaletteItem)? in
            let score = commandScore(item)
            return score > 0 ? (index, score, item) : nil
        }
        .sorted { lhs, rhs in
            if lhs.score == rhs.score { return lhs.index < rhs.index }
            return lhs.score > rhs.score
        }
        .map { $0.item }
    }

    private func commandScore(_ item: CommandPaletteItem) -> Int {
        let title = item.title.lowercased()
        let subtitle = item.subtitle.lowercased()
        let keywords = item.keywords.lowercased()
        let category = commandCategory(item).lowercased()
        var score = 0

        if title == normalizedQuery { score += 1000 }
        if title.hasPrefix(normalizedQuery) { score += 700 }
        if title.split(separator: " ").contains(where: { $0.hasPrefix(normalizedQuery) }) { score += 420 }
        if keywords.contains(normalizedQuery) { score += 260 }
        if subtitle.contains(normalizedQuery) { score += 120 }
        if category.contains(normalizedQuery) { score += 80 }
        if recentCommandIdList.contains(item.id) { score += 30 }
        return score
    }

    private func commandCategory(_ item: CommandPaletteItem) -> String {
        switch item.id {
        case "clone", "source-control": return "Git"
        case "terminal", "new-terminal": return "Terminal"
        case "search", "explorer": return "Workspace"
        case "settings": return "Settings"
        default: return "File"
        }
    }

    private func commandShortcut(_ item: CommandPaletteItem) -> String? {
        switch item.id {
        case "new-file": return "⌘N"
        case "open-file": return "⌘O"
        case "search": return "⇧⌘F"
        case "terminal": return "⌘J"
        case "settings": return "⌘,"
        default: return nil
        }
    }

    private func recordRecent(_ command: CommandPaletteItem) {
        let existing = recentCommandIdList.filter { $0 != command.id }
        recentCommandIds = ([command.id] + existing).prefix(6).joined(separator: ",")
    }

    private func showSidebar(_ itemId: String) {
        activeItemId = itemId
        isSideBarVisible = true
    }

    private func showPanel(_ panelId: String) {
        currentPanelId = panelId
        if panelHeight < 120 {
            panelHeight = 240
        }
        isPanelVisible = true
    }

    private func runCommand(_ command: CommandPaletteItem) {
        recordRecent(command)
        dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            command.action()
        }
    }

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Command Center")
                        .font(.system(.title2, design: .rounded).weight(.bold))
                        .foregroundColor(Color("T1"))
                    Text("Jump into the main workflows without digging through tiny toolbar menus.")
                        .font(.caption)
                        .foregroundColor(Color(id: "tab.inactiveForeground"))
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)

                SearchBar(text: $query, searchAction: nil, placeholder: "Command or action", cornerRadius: 14)
                    .padding(.horizontal, 16)

                ScrollView {
                    LazyVStack(spacing: 9) {
                        if normalizedQuery.isEmpty && !recentCommands.isEmpty {
                            HStack {
                                Label("Recent", systemImage: "clock.arrow.circlepath")
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(Color(id: "tab.inactiveForeground"))
                                Spacer()
                            }
                            ForEach(recentCommands.prefix(4)) { command in
                                Button {
                                    runCommand(command)
                                } label: {
                                    HStack(spacing: 10) {
                                        Image(systemName: command.systemImage)
                                            .foregroundColor(Color(id: "activityBar.foreground"))
                                            .frame(width: 24)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(command.title)
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundColor(Color("T1"))
                                            Text(commandCategory(command))
                                                .font(.caption2.weight(.semibold))
                                                .foregroundColor(Color(id: "tab.inactiveForeground"))
                                        }
                                        Spacer()
                                        Image(systemName: "arrow.turn.down.left")
                                            .font(.caption.weight(.semibold))
                                            .foregroundColor(Color(id: "tab.inactiveForeground"))
                                    }
                                    .padding(10)
                                    .background(Color(id: "button.background").opacity(0.2), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                                }
                                .buttonStyle(.plain)
                            }

                            HStack {
                                Text("All Commands")
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(Color(id: "tab.inactiveForeground"))
                                Spacer()
                            }
                            .padding(.top, 4)
                        }

                        if displayedCommands.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "magnifyingglass")
                                    .font(.title3)
                                    .foregroundColor(Color(id: "tab.inactiveForeground"))
                                Text("No command matches \"\(query)\"")
                                    .font(.callout)
                                    .foregroundColor(Color(id: "tab.inactiveForeground"))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 28)
                        }

                        ForEach(displayedCommands) { command in
                            Button {
                                runCommand(command)
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: command.systemImage)
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(Color(id: "activityBar.foreground"))
                                        .frame(width: 38, height: 38)
                                        .background(Color(id: "button.background").opacity(0.34), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                                    VStack(alignment: .leading, spacing: 3) {
                                        HStack(spacing: 6) {
                                            Text(commandCategory(command))
                                                .font(.caption2.weight(.bold))
                                                .foregroundColor(Color(id: "activityBar.foreground"))
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color(id: "button.background").opacity(0.24), in: Capsule())
                                            if let shortcut = commandShortcut(command) {
                                                Text(shortcut)
                                                    .font(.caption2.monospaced().weight(.semibold))
                                                    .foregroundColor(Color(id: "tab.inactiveForeground"))
                                            }
                                        }
                                        Text(command.title)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundColor(Color("T1"))
                                        Text(command.subtitle)
                                            .font(.caption)
                                            .foregroundColor(Color(id: "tab.inactiveForeground"))
                                            .lineLimit(2)
                                    }
                                    Spacer(minLength: 0)
                                    Image(systemName: "arrow.turn.down.left")
                                        .font(.caption.weight(.semibold))
                                        .foregroundColor(Color(id: "tab.inactiveForeground"))
                                }
                                .padding(12)
                                .background(Color(id: "sideBar.background").opacity(0.58), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .appCodeGlassPanel(cornerRadius: 16, interactive: true)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
            .background(Color(id: "editor.background").ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("Done") { dismiss() }
            }
        }
    }
}

private struct MainView: View {

    @EnvironmentObject var App: MainApp
    @EnvironmentObject var extensionManager: ExtensionManager
    @EnvironmentObject var stateManager: MainStateManager
    @EnvironmentObject var alertManager: AlertManager
    @EnvironmentObject var safariManager: SafariManager
    @EnvironmentObject var directoryPickerManager: DirectoryPickerManager
    @EnvironmentObject var createFileSheetManager: CreateFileSheetManager
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var authenticationRequestManager: AuthenticationRequestManager

    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.colorScheme) var colorScheme: ColorScheme

    @AppStorage("changelog.lastread") var changeLogLastReadVersion = "0.0"
    @AppStorage("runeStoneEditorEnabled") var runeStoneEditorEnabled: Bool = false
    @AppStorage("terminalOptions") var terminalOptions: CodableWrapper<TerminalOptions> = .init(
        value: TerminalOptions())
    @AppStorage("firstRunCommandCenterPresented") var firstRunCommandCenterPresented = false

    @SceneStorage("sidebar.visible") var isSideBarVisible: Bool = DefaultUIState.SIDEBAR_VISIBLE
    @SceneStorage("panel.height") var panelHeight: Double = DefaultUIState.PANEL_HEIGHT
    @SceneStorage("panel.visible") var isPanelVisible: Bool = DefaultUIState.PANEL_IS_VISIBLE

    func openConsolePanel() {
        if panelHeight < 70 {
            panelHeight = 200
        }
        isPanelVisible.toggle()
        App.terminalManager.activeTerminal?.webView.becomeFirstResponder()
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 0) {
                        if horizontalSizeClass == .regular {
                            ActivityBar(togglePanel: openConsolePanel)
                                .environmentObject(extensionManager.activityBarManager)

                            if isSideBarVisible {
                                RegularSidebar(windowWidth: geometry.size.width)
                                    .environmentObject(extensionManager.activityBarManager)
                            }
                        }

                        ZStack {
                            VStack(spacing: 0) {
                                TopBar(openConsolePanel: openConsolePanel)
                                    .environmentObject(extensionManager.toolbarManager)
                                    .frame(height: 40)

                                EditorView()
                                    .disabled(horizontalSizeClass == .compact && isSideBarVisible)
                                    .sheet(isPresented: $stateManager.showsNewFileSheet) {
                                        NewFileView(
                                            targetUrl: App.workSpaceStorage.currentDirectory.url
                                        ).environmentObject(App)
                                    }
                                    .environmentObject(extensionManager.editorProviderManager)

                                if isPanelVisible {
                                    PanelView(
                                        windowHeight: geometry.size.height
                                    )
                                    .environmentObject(extensionManager.panelManager)
                                }
                            }
                            .blur(
                                radius: (horizontalSizeClass == .compact && isSideBarVisible)
                                    ? 10 : 0)

                            if isSideBarVisible && horizontalSizeClass == .compact {
                                CompactSidebar()
                                    .environmentObject(extensionManager.activityBarManager)
                            }
                        }
                    }
                    StatusBar()
                        .environmentObject(extensionManager.statusBarManager)
                        .frame(width: geometry.size.width, height: 20)
                }

                HStack {
                    Spacer()
                    VStack {
                        Spacer()
                        NotificationCentreView().padding(
                            .trailing, (self.horizontalSizeClass == .compact ? 40 : 10))
                    }
                }.padding(.bottom, 30).frame(width: geometry.size.width)

            }
        }
        .background(Color.init(id: "sideBar.background").edgesIgnoringSafeArea(.all))
        .accentColor(Color.init(id: "activityBar.inactiveForeground"))
        .navigationTitle(
            URL(string: App.workSpaceStorage.currentDirectory.url)?.lastPathComponent ?? ""
        )
        .onChange(of: colorScheme) { newValue in
            App.updateView()
        }
        .onChange(of: runeStoneEditorEnabled) { _ in
            App.setUpEditorInstance()
        }
        .onChange(of: terminalOptions) { newValue in
            App.terminalManager.applyOptionsToAll(newValue.value)
        }
        .hiddenScrollableContentBackground()
        .onAppear {
            let appVersion =
                Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0"

            if changeLogLastReadVersion != appVersion {
                stateManager.showsChangeLog.toggle()
            }

            if !firstRunCommandCenterPresented {
                firstRunCommandCenterPresented = true
                if App.editors.isEmpty {
                    App.showWelcomeMessage()
                }
            }

            changeLogLastReadVersion = appVersion
        }
        .alert(
            alertManager.title, isPresented: $alertManager.isShowingAlert,
            actions: {
                alertManager.alertContent
            },
            message: {
                if let message = alertManager.message {
                    Text(message)
                } else {
                    EmptyView()
                }
            }
        )
        .alert(
            authenticationRequestManager.title,
            isPresented: $authenticationRequestManager.isShowingAlert,
            actions: {
                if let usernameTitleKey = authenticationRequestManager.usernameTitleKey {
                    TextField(
                        usernameTitleKey,
                        text: $authenticationRequestManager.username
                    )
                    .textContentType(.username)
                    .disableAutocorrection(true)
                    .autocapitalization(.none)
                }

                if let passwordTitleKey = authenticationRequestManager.passwordTitleKey {
                    SecureField(
                        passwordTitleKey,
                        text: $authenticationRequestManager.password
                    )
                    .textContentType(.password)
                    .disableAutocorrection(true)
                    .autocapitalization(.none)
                }

                Button(
                    "common.cancel", role: .cancel,
                    action: authenticationRequestManager.callbackOnCancel)
                Button("common.continue", action: authenticationRequestManager.callback)
            }
        )
        .sheet(isPresented: $stateManager.showsCommandPalette) {
            CommandPaletteView()
                .environmentObject(App)
                .environmentObject(stateManager)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $safariManager.showsSafari) {
            if let url = safariManager.urlToVisit {
                SafariView(url: url)
            } else {
                EmptyView()
            }
        }
        .sheet(isPresented: $directoryPickerManager.showsPicker) {
            DirectoryPickerView(
                type: directoryPickerManager.type,
                onOpen: { url in
                    directoryPickerManager.callback?(url)
                })
        }
        .sheet(isPresented: $createFileSheetManager.showsSheet) {
            if let targetURL = createFileSheetManager.targetURL {
                NewFileView(targetUrl: targetURL.absoluteString)
            } else {
                EmptyView()
            }
        }
        .hiddenSystemOverlays()
        .ignoresSafeArea(.container, edges: .bottom)
    }
}
