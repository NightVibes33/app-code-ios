//
//  TerminalTabBar.swift
//  Code
//
//  Created by Thales Matheus Mendonça Santos - January 2026
//

import SwiftUI

private enum TerminalTabBarConstants {
    static let tabBarWidth: CGFloat = 92
    static let rowHeight: CGFloat = 42
    static let iconSize: CGFloat = 14
    static let activeIndicatorWidth: CGFloat = 2
}

struct TerminalTabBar: View {
    @EnvironmentObject var App: MainApp

    var body: some View {
        VStack(spacing: 8) {
            Button {
                App.terminalManager.createTerminal()
            } label: {
                Label("New", systemImage: "plus")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(Color("T1"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(Color(id: "button.background").opacity(0.30), in: Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
            .disabled(App.terminalManager.terminals.count >= TerminalManager.maxTerminals)

            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    ForEach(App.terminalManager.terminals) { terminal in
                        TerminalTabRow(
                            terminal: terminal,
                            isActive: terminal.id == App.terminalManager.activeTerminalId,
                            canClose: App.terminalManager.terminals.count > 1,
                            onSelect: {
                                App.terminalManager.setActiveTerminal(id: terminal.id)
                            },
                            onKill: {
                                App.terminalManager.stopTerminal(id: terminal.id)
                            },
                            onClose: {
                                App.terminalManager.closeTerminal(id: terminal.id)
                            }
                        )
                    }
                }
            }
        }
        .frame(width: TerminalTabBarConstants.tabBarWidth)
        .padding(.horizontal, 6)
        .background(Color(id: "sideBar.background"))
    }
}

struct TerminalTabRow: View {
    @EnvironmentObject var App: MainApp

    let terminal: TerminalInstance
    let isActive: Bool
    let canClose: Bool
    let onSelect: () -> Void
    let onKill: () -> Void
    let onClose: () -> Void

    @State private var showingKillConfirmation = false

    private var isTerminalBusy: Bool {
        App.terminalManager.isTerminalBusy(id: terminal.id)
    }

    private var accessibilityLabel: String {
        let activeLabel = NSLocalizedString(
            "terminal.tab.accessibility.active",
            comment: "Accessibility label for active terminal"
        )
        let runningLabel = NSLocalizedString(
            "terminal.tab.accessibility.running",
            comment: "Accessibility label for running terminal"
        )
        var parts = [terminal.name]
        if isActive {
            parts.append(activeLabel)
        }
        if isTerminalBusy {
            parts.append(runningLabel)
        }
        return parts.joined(separator: ", ")
    }

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: isTerminalBusy ? "terminal.fill" : "terminal")
                .font(.system(size: TerminalTabBarConstants.iconSize, weight: .semibold))
                .foregroundColor(Color(id: "foreground"))
                .frame(width: 20, height: 20)
            Text(terminal.name)
                .font(.caption2.weight(isActive ? .semibold : .regular))
                .foregroundColor(Color(id: "foreground"))
                .lineLimit(1)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
        .frame(height: TerminalTabBarConstants.rowHeight)
        .background(Color(id: "button.background").opacity(isActive ? 0.26 : 0), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            // Left border indicator for active tab (VS Code style)
            HStack {
                if isActive {
                    Rectangle()
                        .fill(Color.accentColor)
                        .frame(width: TerminalTabBarConstants.activeIndicatorWidth)
                }
                Spacer()
            }
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(isActive ? [.isSelected, .isButton] : [.isButton])
        .accessibilityHint(
            NSLocalizedString(
                "terminal.tab.accessibility.hint",
                comment: "Accessibility hint for terminal tab")
        )
        .contextMenu {
            Button(role: .destructive) {
                onKill()
            } label: {
                Label("Stop Command", systemImage: "stop.fill")
            }

            if canClose {
                Button(role: .destructive) {
                    if isTerminalBusy {
                        showingKillConfirmation = true
                    } else {
                        onClose()
                    }
                } label: {
                    Label("terminal.tab.kill", systemImage: "xmark")
                }
            }
        }
        .alert(
            "terminal.tab.kill_confirmation.title",
            isPresented: $showingKillConfirmation
        ) {
            Button("terminal.tab.kill_confirmation.cancel", role: .cancel) {}
            Button("terminal.tab.kill_confirmation.kill", role: .destructive) {
                onClose()
            }
        } message: {
            Text(
                "terminal.tab.kill_confirmation.message")
        }
    }
}
