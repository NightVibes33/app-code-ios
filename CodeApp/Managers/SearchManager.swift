//
//  searchManager.swift
//  Code
//
//  Created by Ken Chung on 12/4/2021.
//

import Foundation
import ios_system

class TextSearchManager: ObservableObject {

    @Published var searchTerm = ""
    @Published var message = ""
    @Published var expansionStates: [String: Bool] = [:]
    @Published var results: [String: [SearchResult]] = [:]
    @Published var isSearching = false
    @Published var includePattern = ""
    @Published var excludePattern = "node_modules,.git"

    var executor: Executor? = nil
    private var resultCount = 0

    private var tempResponse = ""

    init() {
        executor = Executor(
            root: URL(fileURLWithPath: FileManager().currentDirectoryPath),
            onStdout: { data in
                if let mes = String(data: data, encoding: .utf8) {
                    self.tempResponse += mes
                }
            },
            onStderr: { data in
                if let mes = String(data: data, encoding: .utf8) {
                    self.tempResponse += mes
                }
            },
            onRequestInput: { data in
                self.tempResponse += data
            })
    }

    private func parseResult() {
        for line in tempResponse.components(separatedBy: "\n") {
            let components = line.components(separatedBy: ":")
            if components.count < 3 {
                continue
            }
            let path = components[0]
            guard let linenum = Int(components[1]), FileManager.default.fileExists(atPath: path)
            else {
                continue
            }
            let line = components.dropFirst(2).joined().trimmingCharacters(in: .whitespaces)
            if expansionStates[path] == nil {
                expansionStates[path] = true
            }
            resultCount += 1
            if results[path] == nil {
                results[path] = [SearchResult(line_num: linenum, line: line)]
            } else {
                results[path]?.append(SearchResult(line_num: linenum, line: line))
            }
        }
        self.message =
            "\(self.resultCount) result\(self.resultCount > 1 ? "s" : "") in \(self.results.keys.count) file\(self.results.keys.count > 1 ? "s" : "")"
    }

    func removeAllResults() {
        results.removeAll()
        message.removeAll()
        tempResponse.removeAll()
        resultCount = 0
        isSearching = false
    }

    func cancelSearch() {
        executor?.kill()
        isSearching = false
        message = "Search cancelled"
    }

    private func shellEscaped(_ value: String) -> String {
        let singleQuote = "'"
        return singleQuote + value.replacingOccurrences(
            of: singleQuote,
            with: singleQuote + "\\" + singleQuote + singleQuote
        ) + singleQuote
    }

    private var grepExcludes: String {
        excludePattern
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .map { "--exclude-dir=\(shellEscaped($0))" }
            .joined(separator: " ")
    }

    private var grepIncludes: String {
        includePattern
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .map { "--include=\(shellEscaped($0))" }
            .joined(separator: " ")
    }

    func search(str: String, path: String) {
        let term = str.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else {
            removeAllResults()
            return
        }

        results = [:]
        message = "Searching..."
        tempResponse = ""
        resultCount = 0
        isSearching = true

        let command = "grep -rin \(grepExcludes) \(grepIncludes) -m 1000 \(shellEscaped(term)) \(shellEscaped(path))"
        executor?.dispatch(command: command) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.parseResult()
                self.tempResponse = ""
                self.isSearching = false
            }
        }
    }
}
