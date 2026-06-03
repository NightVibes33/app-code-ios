//
//  GitHubSearchManager.swift
//  Code App
//
//  Created by Ken Chung on 5/12/2020.
//

import SwiftUI

class GitHubSearchManager: ObservableObject {

    @Published var searchResultItems: [item] = []
    @Published var templates: [item]? = nil
    @Published var searchTerm: String = ""
    @Published var errorMessage: String = ""
    @Published var isSearching = false

    private var searchTask: Task<Void, Never>?

    static let endpoint = "https://api.github.com/search/repositories"

    struct searchResult: Decodable {
        let items: [item]
    }

    struct item: Decodable {
        let name: String
        let html_url: String
        let clone_url: String
        let description: String?
        let stargazers_count: Int
        let size: Int
        let language: String?
        let owner: owner
    }

    struct owner: Decodable {
        let login: String
        let avatar_url: String
    }

    func search() {
        searchTask?.cancel()
        startSearch(for: searchTerm)
    }

    func searchDebounced() {
        searchTask?.cancel()
        let term = searchTerm.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else {
            searchResultItems = []
            errorMessage = ""
            isSearching = false
            return
        }
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 450_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                self.startSearch(for: term)
            }
        }
    }

    private func startSearch(for term: String) {
        let trimmedTerm = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTerm.isEmpty else {
            searchResultItems = []
            errorMessage = ""
            isSearching = false
            return
        }

        let query = trimmedTerm + "&per_page=10"
        isSearching = true
        errorMessage = ""

        searchTask = Task {
            do {
                let items = try await executeQuery(query: query)
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    self.searchResultItems = items
                    self.isSearching = false
                }
            } catch {
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isSearching = false
                }
            }
        }
    }

    func listTemplates() {
        let query = "topic:codeapp-template sort:stars"
        Task {
            do {
                let templates = try await executeQuery(query: query)
                await MainActor.run {
                    self.templates = templates
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.templates = []
                }
            }
        }
    }

    private func executeQuery(query: String) async throws -> [item] {
        guard let query = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        else {
            return []
        }
        let url = URL(string: GitHubSearchManager.endpoint + "?q=\(query)")!

        let (data, _) = try await URLSession.shared.data(from: url)
        let result = try JSONDecoder().decode(searchResult.self, from: data)
        return result.items
    }
}
