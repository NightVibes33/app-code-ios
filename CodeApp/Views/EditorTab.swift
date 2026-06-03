//
//  editorTab.swift
//  Code
//
//  Created by Ken Chung on 16/5/2021.
//

import SwiftUI

struct EditorTab: View {

    @EnvironmentObject var App: MainApp
    @EnvironmentObject var themeManager: ThemeManager

    // TODO: Don't use ObservedObject because it leaks memory
    @ObservedObject var currentEditor: EditorInstance
    var isActive: Bool
    var onOpenEditor: () -> Void
    var onCloseEditor: () -> Void

    var index: Int {
        App.editors.firstIndex { $0 == currentEditor } ?? 0
    }

    static private func keyForInt(int: Int) -> KeyEquivalent {
        if int < 10 {
            return KeyEquivalent.init(String(int).first!)
        }
        return KeyEquivalent.init("0")
    }

    private var isUnsaved: Bool {
        (currentEditor as? TextEditorInstance)?.isSaved == false
    }

    private var isDeleted: Bool {
        (currentEditor as? TextEditorInstance)?.isDeleted == true
    }

    var body: some View {
        HStack(spacing: 7) {
            FileIcon(url: currentEditor.title, iconSize: 13)

            Button(action: onOpenEditor) {
                HStack(spacing: 4) {
                    if let editorURL = (currentEditor as? EditorInstanceWithURL)?.url,
                        let status = App.gitTracks[editorURL]
                    {
                        FileDisplayName(
                            gitStatus: status,
                            name: currentEditor.title,
                            useAllSpaceAvailableHorizontally: false)
                    } else {
                        FileDisplayName(
                            gitStatus: nil,
                            name: currentEditor.title,
                            useAllSpaceAvailableHorizontally: false)
                    }
                    if isDeleted {
                        Text("(deleted)")
                            .italic()
                            .foregroundColor(Color(id: "tab.inactiveForeground"))
                    }
                }
                .lineLimit(1)
                .font(.system(size: 13, weight: isActive ? .semibold : .regular))
                .foregroundColor(
                    Color.init(id: isActive ? "tab.activeForeground" : "tab.inactiveForeground")
                )
            }
            .buttonStyle(.plain)
            .keyboardShortcut(EditorTab.keyForInt(int: index + 1), modifiers: .command)

            Button(action: onCloseEditor) {
                Image(systemName: isUnsaved ? "circle.fill" : "xmark")
                    .font(.system(size: isUnsaved ? 7 : 9, weight: .semibold))
                    .foregroundColor(Color.init(id: isActive ? "tab.activeForeground" : "tab.inactiveForeground"))
                    .frame(width: 24, height: 24)
                    .background(Color(id: "button.background").opacity(isActive ? 0.18 : 0), in: Circle())
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isUnsaved ? "Unsaved file" : "Close editor")
        }
        .frame(height: 40)
        .padding(.horizontal, 9)
        .background(
            Color(id: isActive ? "tab.activeBackground" : "sideBar.background").opacity(isActive ? 1 : 0.18),
            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
        )
        .overlay(alignment: .bottom) {
            if isActive {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(Color(id: "activityBar.foreground"))
                    .frame(height: 2)
                    .padding(.horizontal, 9)
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .onTapGesture(perform: onOpenEditor)
    }

}
