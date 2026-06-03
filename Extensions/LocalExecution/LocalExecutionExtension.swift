//
//  LocalExecutionExtension.swift
//  Code
//
//  Created by Ken Chung on 19/11/2022.
//

import Foundation

private let EXTENSION_ID = "LOCAL_EXECUTION"

private let LOCAL_EXECUTION_COMMANDS = [
    "py": ["python3 -u {url}"],
    "js": ["node {url}"],
    "c": ["clang {url}", "wasm a.out"],
    "cpp": ["clang++ {url}", "wasm a.out"],
    "php": ["php {url}"],
    "java": [
        "javac {url}",
        "java -classpath \"{url_parent}\" \"{last_path_component_without_extension}\"",
    ],
]

class LocalExecutionExtension: CodeAppExtension {
    override func onInitialize(app: MainApp, contribution: CodeAppExtension.Contribution) {
        let toolbarItem = ToolbarItem(
            extenionID: EXTENSION_ID,
            icon: "play",
            onClick: {
                Task {
                    await self.runCodeLocally(app: app)
                }
            },
            shortCut: .init("r", modifiers: [.command]),
            panelToFocusOnTap: "TERMINAL",
            shouldDisplay: { app in
                guard let activeTextEditor = app.activeTextEditor else { return false }
                return activeTextEditor.url.isFileURL
                    && LOCAL_EXECUTION_COMMANDS[activeTextEditor.languageIdentifier] != nil
            }
        )
        contribution.toolBar.registerItem(item: toolbarItem)
    }

    @MainActor
    private func waitForTerminalReady(_ terminal: TerminalInstance) async -> Bool {
        if terminal.isReady {
            return true
        }

        for _ in 0..<20 {
            try? await Task.sleep(nanoseconds: 100_000_000)
            if terminal.isReady {
                return true
            }
        }

        return terminal.isReady
    }

    @MainActor
    private func terminalForLocalExecution(app: MainApp) -> TerminalInstance? {
        if let activeTerminal = app.terminalManager.activeTerminal,
            activeTerminal.terminalServiceProvider == nil,
            activeTerminal.executor?.state == .idle
        {
            return activeTerminal
        }

        if let idleTerminal = app.terminalManager.terminals.first(where: {
            $0.terminalServiceProvider == nil && $0.executor?.state == .idle
        }) {
            app.terminalManager.setActiveTerminal(id: idleTerminal.id)
            return idleTerminal
        }

        if app.terminalManager.canCreateNewTerminal {
            let terminal = app.terminalManager.createTerminal()
            app.notificationManager.showInformationMessage(
                "Running in \(terminal.name) because the active terminal is busy.")
            return terminal
        }

        return nil
    }

    @MainActor
    private func runCodeLocally(app: MainApp) async {
        guard let activeTextEditor = app.activeTextEditor else {
            return
        }

        guard let commands = LOCAL_EXECUTION_COMMANDS[activeTextEditor.languageIdentifier] else {
            return
        }

        guard let executionTerminal = terminalForLocalExecution(app: app) else {
            app.notificationManager.showWarningMessage(
                "All terminals are busy. Stop a running command or wait for it to finish before running code."
            )
            return
        }

        guard let executor = executionTerminal.executor else {
            app.notificationManager.showErrorMessage(
                "Cannot run: terminal '\(executionTerminal.name)' has no executor.")
            return
        }

        guard await waitForTerminalReady(executionTerminal) else {
            app.notificationManager.showWarningMessage(
                "Terminal is still starting. Try again in a moment.")
            return
        }

        await app.saveCurrentFile()

        let sanitizedUrl = activeTextEditor.url.path.replacingOccurrences(of: " ", with: #"\ "#)
        let urlParent = activeTextEditor.url.deletingLastPathComponent().path
        let lastPathComponentWithoutExtension = activeTextEditor.url.deletingPathExtension()
            .lastPathComponent
            .replacingOccurrences(of: " ", with: #"\ "#)
        let parsedCommands = commands.map {
            $0
                .replacingOccurrences(of: "{url}", with: sanitizedUrl)
                .replacingOccurrences(of: "{url_parent}", with: urlParent)
                .replacingOccurrences(
                    of: "{last_path_component_without_extension}",
                    with: lastPathComponentWithoutExtension)
        }

        if app.terminalOptions.value.shouldShowCompilerPath {
            executionTerminal.executeScript(
                "localEcho.println(`\(parsedCommands.joined(separator: " && "))`);readLine('');")
        } else {
            let commandName =
                parsedCommands.first?.components(separatedBy: " ").first
                ?? activeTextEditor.languageIdentifier
            executionTerminal.executeScript("localEcho.println(`\(commandName)`);readLine('');")
        }
        executor.evaluateCommands(parsedCommands)
    }
}
