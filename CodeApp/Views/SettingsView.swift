//
//  SettingsView.swift
//  App Code
//
//  Created by Ken Chung on 5/12/2020.
//

import SwiftUI
import UIKit

struct SettingsView: View {

    @EnvironmentObject var App: MainApp
    @EnvironmentObject var themeManager: ThemeManager

    @AppStorage("suggestionEnabled") var suggestionEnabled: Bool = true
    @AppStorage("editorShowKeyboardButtonEnabled") var editorShowKeyboardButtonEnabled: Bool = true
    @AppStorage("preferredColorScheme") var preferredColorScheme: Int = 0
    @AppStorage("explorer.showHiddenFiles") var showHiddenFiles: Bool = false
    @AppStorage("explorer.confirmBeforeDelete") var confirmBeforeDelete = false
    @AppStorage("alwaysOpenInNewTab") var alwaysOpenInNewTab: Bool = false
    @AppStorage("stateRestorationEnabled") var stateRestorationEnabled = true
    @AppStorage("communityTemplatesEnabled") var communityTemplatesEnabled = true
    @AppStorage("editorOptions") var editorOptions: CodableWrapper<EditorOptions> = .init(
        value: EditorOptions())
    @AppStorage("terminalOptions") var terminalOptions: CodableWrapper<TerminalOptions> = .init(
        value: TerminalOptions())
    @AppStorage("runeStoneEditorEnabled") var runeStoneEditorEnabled: Bool = false
    @AppStorage("languageServiceEnabled") var languageServiceEnabled: Bool = true

    @State var showAllFonts = false
    @State var showsEraseAlert: Bool = false
    @State var showReceiptInformation: Bool = false
    @State private var settingsSearch = ""

    let colorSchemes = ["Automatic", "Dark", "Light"]
    let renderWhitespaceOptions = ["None", "Boundary", "Selection", "Trailing", "All"]
    let wordWrapOptions = ["off", "on", "wordWrapColumn", "bounded"]

    private var selectedColorSchemeLabel: String {
        colorSchemes.indices.contains(preferredColorScheme) ? colorSchemes[preferredColorScheme] : colorSchemes[0]
    }

    private var settingsDebugInfo: String {
        [
            "App Code Settings Debug",
            "Color scheme: \(selectedColorSchemeLabel)",
            "Editor font size: \(editorOptions.value.fontSize)",
            "Terminal font size: \(terminalOptions.value.fontSize)",
            "Language service: \(languageServiceEnabled)",
            "State restoration: \(stateRestorationEnabled)",
            "Hidden files: \(showHiddenFiles)",
            "Community templates: \(communityTemplatesEnabled)",
            "Workspace: \(App.workSpaceStorage.currentDirectory.url)",
        ].joined(separator: "\n")
    }

    private func copyDebugInfo() {
        UIPasteboard.general.string = settingsDebugInfo + "\n\n" + App.notificationManager.debugSummary()
        App.notificationManager.showInformationMessage("Debug info copied")
    }

    private func sendFeedback() {
        copyDebugInfo()
        let subject = "App Code Feedback".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "App%20Code%20Feedback"
        let body = settingsDebugInfo.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "mailto:?subject=\(subject)&body=\(body)") {
            UIApplication.shared.open(url)
        }
    }

    @Environment(\.presentationMode) var presentationMode
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    var body: some View {
        NavigationView {
            Form {
                // TODO: Rework Editor / Terminal settings to support multiple scenes

                SettingsOverviewCard(
                    colorScheme: selectedColorSchemeLabel,
                    editorFontSize: editorOptions.value.fontSize,
                    terminalFontSize: terminalOptions.value.fontSize,
                    languageServiceEnabled: languageServiceEnabled,
                    restorationEnabled: stateRestorationEnabled
                )
                .listRowInsets(EdgeInsets(top: 16, leading: 16, bottom: 8, trailing: 16))
                .listRowBackground(Color.clear)

                SettingsSearchCard(searchText: $settingsSearch)
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)

                SettingsQuickMapCard(onSelect: { settingsSearch = $0 })
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 10, trailing: 16))
                    .listRowBackground(Color.clear)

                Group {
                    Section(header: Text(NSLocalizedString("General", comment: ""))) {
                        NavigationLink(
                            destination:
                                SettingsThemeConfiguration()
                                .environmentObject(App)
                        ) {
                            Text("Themes")
                        }

                        Picker(selection: $preferredColorScheme, label: Text("Color Scheme")) {
                            ForEach(0..<colorSchemes.count, id: \.self) {
                                Text(self.colorSchemes[$0])
                            }
                        }
                        Stepper(
                            "\(NSLocalizedString("Editor Font Size", comment: "")) (\(editorOptions.value.fontSize))",
                            value: $editorOptions.value.fontSize, in: 10...30
                        )

                        Stepper(
                            "\(NSLocalizedString("Console Font Size", comment: "")) (\(terminalOptions.value.fontSize))",
                            value: $terminalOptions.value.fontSize, in: 8...24)

                        Button(action: {
                            guard let url = URL(string: "https://github.com/NightVibes33/app-code-ios")
                            else { return }
                            UIApplication.shared.open(url)
                        }) {
                            Text("Open an Issue on GitHub")
                        }
                        Button(action: sendFeedback) {
                            Label("Send Feedback", systemImage: "paperplane")
                        }
                        Button(action: copyDebugInfo) {
                            Label("Copy Debug Info", systemImage: "doc.on.doc")
                        }
                    }

                    Section(header: Text(NSLocalizedString("Version Control", comment: ""))) {
                        NavigationLink(destination: SourceControlIdentityConfiguration()) {
                            Text("Author Identity")
                        }
                        NavigationLink(destination: SourceControlAuthenticationConfiguration()) {
                            Text("Authentication")
                        }
                        Toggle(
                            "source_control.community_templates", isOn: $communityTemplatesEnabled)
                    }

                    Section(header: Text(NSLocalizedString("EXPLORER", comment: ""))) {
                        Toggle("settings.explorer.show_hidden_files", isOn: $showHiddenFiles)
                        Toggle(
                            "settings.explorer.confirm_before_delete", isOn: $confirmBeforeDelete)
                    }

                    Section(
                        content: {
                            Toggle(
                                "settings.language_service.enable", isOn: $languageServiceEnabled)
                        }, header: { Text("settings.language_service") },
                        footer: { Text("settings.language_service.notes") })

                    Section(header: Text(NSLocalizedString("Editor", comment: ""))) {

                        Toggle("settings.editor.vim.enabled", isOn: $editorOptions.value.vimEnabled)

                        NavigationLink(
                            destination: SettingsFontPicker(
                                showAllFonts: $showAllFonts,
                                onFontPick: { descriptor in
                                    CTFontManagerRequestFonts([descriptor] as CFArray) { _ in
                                        editorOptions.value.fontFamily =
                                            descriptor.object(forKey: .family) as! String
                                    }
                                }
                            ).toolbar {
                                Button("Show all fonts") {
                                    showAllFonts.toggle()
                                }

                                Button("settings.editor.font.reset") {
                                    editorOptions.value.fontFamily = "Menlo"
                                }
                                .disabled(editorOptions.value.fontFamily == "Menlo")
                            },
                            label: {
                                HStack {
                                    Text("settings.editor.font")
                                    Spacer()
                                    Text(editorOptions.value.fontFamily)
                                        .foregroundColor(.gray)
                                }
                            }
                        )

                        Toggle("settings.editor.font.show_all_fonts", isOn: $showAllFonts)

                        Toggle(
                            "settings.editor.font.ligatures",
                            isOn: $editorOptions.value.fontLigaturesEnabled)

                        NavigationLink(
                            destination:
                                SettingsKeyboardShortcuts()
                                .environmentObject(App)
                        ) {
                            Text("Custom Keyboard Shortcuts")
                        }

                        Group {
                            Stepper(
                                "\(NSLocalizedString("Tab Size", comment: "")) (\(editorOptions.value.tabRenderSize))",
                                value: $editorOptions.value.tabRenderSize, in: 1...8
                            )
                        }

                        Group {
                            Toggle("Read-only Mode", isOn: $editorOptions.value.readOnly)
                            Toggle("UI State Restoration", isOn: self.$stateRestorationEnabled)
                        }

                        Group {
                            Toggle(
                                NSLocalizedString("Bracket Completion", comment: ""),
                                isOn: $editorOptions.value.autoClosingBrackets
                            )

                            Toggle(
                                NSLocalizedString("Mini Map", comment: ""),
                                isOn: $editorOptions.value.miniMapEnabled
                            )

                            Toggle(
                                NSLocalizedString("Line Numbers", comment: ""),
                                isOn: $editorOptions.value.lineNumbersEnabled
                            )

                            Toggle(
                                "Keyboard Toolbar",
                                isOn: $editorOptions.value.toolBarEnabled
                            ).onChange(
                                of: editorOptions.value.toolBarEnabled
                            ) { value in
                                NotificationCenter.default.post(
                                    name: Notification.Name("toolbarSettingChanged"), object: nil,
                                    userInfo: ["enabled": value])
                            }

                            Toggle("Always Open In New Tab", isOn: self.$alwaysOpenInNewTab)

                            Toggle(
                                NSLocalizedString("Smooth Scrolling", comment: ""),
                                isOn: $editorOptions.value._smoothScrollingEnabled
                            )
                        }

                        Group {
                            Picker(
                                NSLocalizedString("Text Wrap", comment: ""),
                                selection: $editorOptions.value.wordWrap
                            ) {
                                ForEach(WordWrapOption.allCases, id: \.self) {
                                    Text(verbatim: "\($0)")
                                }
                            }

                            Picker(
                                selection: $editorOptions.value.renderWhiteSpaces,
                                label: Text("Render Whitespace")
                            ) {
                                ForEach(RenderWhiteSpaceMode.allCases, id: \.self) {
                                    Text(verbatim: "\($0)")
                                }
                            }
                        }
                    }

                    Section(
                        content: {
                            Toggle("settings.runestone.editor", isOn: $runeStoneEditorEnabled)
                        }, header: { Text("settings.runestone.editor") },
                        footer: { Text("settings.runestone.editor.notes") })

                    Section(header: Text("TERMINAL")) {
                        NavigationLink(
                            destination: SettingsFontPicker(
                                showAllFonts: $showAllFonts,
                                onFontPick: { descriptor in
                                    CTFontManagerRequestFonts([descriptor] as CFArray) { _ in
                                        terminalOptions.value.fontFamily =
                                            descriptor.object(forKey: .family) as! String
                                    }
                                }
                            ).toolbar {
                                Button("Show all fonts") {
                                    showAllFonts.toggle()
                                }

                                Button("settings.editor.font.reset") {
                                    terminalOptions.value.fontFamily = TerminalOptions().fontFamily
                                }
                                .disabled(
                                    terminalOptions.value.fontFamily == TerminalOptions().fontFamily
                                )
                            },
                            label: {
                                HStack {
                                    Text("settings.terminal.font")
                                    Spacer()
                                    Text(terminalOptions.value.fontFamily)
                                        .foregroundColor(.gray)
                                }
                            }
                        )

                        Toggle("Keyboard Toolbar", isOn: $terminalOptions.value.toolbarEnabled)
                        Toggle(
                            "Show Command in Terminal",
                            isOn: $terminalOptions.value.shouldShowCompilerPath)
                    }

                    Section(header: Text(NSLocalizedString("About", comment: ""))) {

                        NavigationLink(
                            destination: SimpleMarkDownView(
                                text: NSLocalizedString("Changelog.message", comment: ""))
                        ) {
                            Text(NSLocalizedString("Release Notes", comment: ""))
                        }

                        Link(
                            "settings.about.change_app_language",
                            destination: URL(string: UIApplication.openSettingsURLString)!)
                        Link(
                            "terms_of_use",
                            destination: URL(
                                string:
                                    "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"
                            )!
                        )
                        Link(
                            "code.and.privacy",
                            destination: URL(string: "https://github.com/NightVibes33/app-code-ios/blob/main/PRIVACY.md")!)

                        NavigationLink(
                            destination: SimpleMarkDownView(
                                text: NSLocalizedString("licenses", comment: ""))
                        ) {
                            Text("Licenses")
                        }
                        HStack {
                            Text(NSLocalizedString("Version", comment: ""))
                            Spacer()
                            Text(
                                (Bundle.main.infoDictionary?["CFBundleShortVersionString"]
                                    as? String
                                    ?? "0.0") + " Build "
                                    + (Bundle.main.infoDictionary?["CFBundleVersion"] as? String
                                        ?? "0")
                            )
                        }

                        Button(action: {
                            showsEraseAlert.toggle()
                        }) {
                            Text(NSLocalizedString("Erase all settings", comment: ""))
                                .foregroundColor(
                                    .red)
                        }
                        .alert(isPresented: $showsEraseAlert) {
                            Alert(
                                title: Text(NSLocalizedString("Erase all settings", comment: "")),
                                message: Text(
                                    NSLocalizedString(
                                        "This will erase all user settings, including author identity and credentials.",
                                        comment: "")),
                                primaryButton: .destructive(
                                    Text(NSLocalizedString("Erase", comment: ""))
                                ) {
                                    UserDefaults.standard.dictionaryRepresentation().keys.forEach {
                                        key in
                                        UserDefaults.standard.removeObject(forKey: key)
                                    }
                                    KeychainWrapper.standard.set("", forKey: "git-username")
                                    KeychainWrapper.standard.set("", forKey: "git-password")
                                    NSUserActivity.deleteAllSavedUserActivities {}
                                    App.notificationManager.showInformationMessage(
                                        "All settings erased")
                                }, secondaryButton: .cancel())
                        }

                        Text("App Code by NightVibes").font(.footnote).foregroundColor(.gray)
                            .onTapGesture(
                                count: 2,
                                perform: {
                                    showReceiptInformation = true
                                })
                    }

                }
                .listRowBackground(Color.init(id: "list.inactiveSelectionBackground"))
            }
            .navigationBarTitle("Settings", displayMode: .inline)
            .navigationBarItems(
                trailing:
                    Button(NSLocalizedString("Done", comment: "")) {
                        self.presentationMode.wrappedValue.dismiss()
                    }
            )
            .configureToolbarBackground()
            .preferredColorScheme(themeManager.colorSchemePreference)
        }
    }
}

private struct SettingsQuickMapItem: Identifiable {
    let title: String
    let subtitle: String
    let systemImage: String
    var id: String { title }
}

private struct SettingsSearchCard: View {
    @Binding var searchText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SearchBar(text: $searchText, searchAction: nil, placeholder: "Find a setting", cornerRadius: 14)
            if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Label("Quick map focused on \(searchText)", systemImage: "scope")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(Color(id: "tab.inactiveForeground"))
            }
        }
        .padding(12)
        .background(Color(id: "sideBar.background").opacity(0.50), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .appCodeGlassPanel(cornerRadius: 16, interactive: false)
    }
}

private struct SettingsQuickMapCard: View {
    let onSelect: (String) -> Void

    private let items = [
        SettingsQuickMapItem(title: "Editor", subtitle: "Font, tabs, wrapping", systemImage: "text.cursor"),
        SettingsQuickMapItem(title: "Terminal", subtitle: "Shell font and toolbar", systemImage: "terminal"),
        SettingsQuickMapItem(title: "Git", subtitle: "Identity and auth", systemImage: "arrow.triangle.branch"),
        SettingsQuickMapItem(title: "Workspace", subtitle: "Files and restore", systemImage: "folder")
    ]

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 142), spacing: 8)], alignment: .leading, spacing: 8) {
            ForEach(items) { item in
                Button {
                    onSelect(item.title)
                } label: {
                    HStack(spacing: 9) {
                        Image(systemName: item.systemImage)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(id: "activityBar.foreground"))
                            .frame(width: 28, height: 28)
                            .background(Color(id: "button.background").opacity(0.30), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                        VStack(alignment: .leading, spacing: 1) {
                            Text(item.title)
                                .font(.caption.weight(.semibold))
                                .foregroundColor(Color("T1"))
                            Text(item.subtitle)
                                .font(.caption2)
                                .foregroundColor(Color(id: "tab.inactiveForeground"))
                                .lineLimit(1)
                        }
                        Spacer(minLength: 0)
                        Image(systemName: "magnifyingglass")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(Color(id: "tab.inactiveForeground"))
                    }
                    .padding(10)
                    .background(Color(id: "sideBar.background").opacity(0.50), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .appCodeGlassPanel(cornerRadius: 14, interactive: true)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct SettingsOverviewCard: View {
    let colorScheme: String
    let editorFontSize: Int
    let terminalFontSize: Int
    let languageServiceEnabled: Bool
    let restorationEnabled: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 13) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(Color(id: "activityBar.foreground"))
                    .frame(width: 46, height: 46)
                    .background(Color(id: "button.background").opacity(0.34), in: RoundedRectangle(cornerRadius: 15, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text("Settings")
                        .font(.headline)
                        .foregroundColor(Color("T1"))
                    Text("Tune the editor, terminal, Git, and workspace startup in one place.")
                        .font(.caption)
                        .foregroundColor(Color(id: "tab.inactiveForeground"))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 128), spacing: 8)], alignment: .leading, spacing: 8) {
                SettingsStatusPill(title: colorScheme, systemImage: "circle.lefthalf.filled")
                SettingsStatusPill(title: "Editor \(editorFontSize)pt", systemImage: "textformat.size")
                SettingsStatusPill(title: "Terminal \(terminalFontSize)pt", systemImage: "terminal")
                SettingsStatusPill(
                    title: languageServiceEnabled ? "Language Service On" : "Language Service Off",
                    systemImage: languageServiceEnabled ? "checkmark.seal" : "xmark.seal"
                )
                SettingsStatusPill(
                    title: restorationEnabled ? "Restores Tabs" : "No Tab Restore",
                    systemImage: restorationEnabled ? "arrow.clockwise" : "rectangle.slash"
                )
            }
        }
        .padding(16)
        .background(Color(id: "sideBar.background").opacity(0.62), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .appCodeGlassPanel(cornerRadius: 18, interactive: false)
    }
}

private struct SettingsStatusPill: View {
    let title: String
    let systemImage: String

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .foregroundColor(Color("T1"))
            .lineLimit(1)
            .minimumScaleFactor(0.78)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(id: "button.background").opacity(0.30), in: Capsule())
    }
}

extension View {
    @ViewBuilder
    func configureToolbarBackground() -> some View {
        if #available(iOS 16.4, *) {
            self
                .toolbarBackground(
                    Color.init(id: "editor.background"), for: .navigationBar
                )
        } else {
            self
        }
    }
}
