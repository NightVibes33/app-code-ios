//
//  NewRemote.swift
//  Code
//
//  Created by Ken Chung on 11/4/2022.
//

import SwiftUI
import UIKit

struct RemoteCreateSection: View {
    enum Field: Hashable {
        case address
        case port
        case username
        case password
        case privateKeyContent
    }

    let hosts: [RemoteHost]
    let onConnectToHostWithCredentials: (RemoteHost, URLCredential) async throws -> Void
    let onSaveHost: (RemoteHost) -> Void
    let onSaveCredentialsForHost: (RemoteHost, URLCredential) throws -> Void

    @EnvironmentObject var App: MainApp

    @State var saveAddress: Bool = true
    @State var serverType: RemoteType = .sftp
    @State var address: String = ""
    @State var password: String = ""
    @State var privateKeyContent: String = ""
    @State var usesPrivateKey: Bool = false
    @State var showFileImporter: Bool = false
    @State var port: String = "22"
    @State var saveCredentials: Bool = true
    @State var username: String = ""
    @State var hasSSHKey = true
    @State var usesJumpServer = false
    @State var jumpServerUrl: String? = nil

    @FocusState var focusedField: Field?

    var hostsSuitableForJumphost: [RemoteHost] {
        hosts.filter { $0.url.hasPrefix("sftp") && $0.jumpServerUrl == nil }
    }

    func resetAllFields() {
        saveAddress = true
        serverType = .sftp
        address = ""
        password = ""
        privateKeyContent = ""
        usesPrivateKey = false
        showFileImporter = false
        port = "22"
        saveCredentials = false
        username = ""
        hasSSHKey = true
    }

    private var connectionPreview: String {
        let user = username.isEmpty ? "user" : username
        let host = address.isEmpty ? "host" : address
        return "\(user)@\(host):\(port.isEmpty ? "22" : port)"
    }

    private func parseConnectionString(_ rawValue: String) {
        var value = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else {
            App.notificationManager.showInformationMessage("Clipboard is empty.")
            return
        }

        if value.hasPrefix("ssh ") {
            value = value.replacingOccurrences(of: "ssh ", with: "")
        }
        if value.hasPrefix("sftp://") || value.hasPrefix("ssh://") {
            if let url = URL(string: value) {
                address = url.host ?? address
                username = url.user ?? username
                port = url.port.map(String.init) ?? port
                serverType = .sftp
                App.notificationManager.showInformationMessage("Remote fields filled from URL")
                return
            }
        }

        let parts = value.split(separator: " ").map(String.init)
        if let portFlagIndex = parts.firstIndex(of: "-p"), parts.indices.contains(portFlagIndex + 1) {
            port = parts[portFlagIndex + 1]
        }
        let target = parts.first(where: { !$0.hasPrefix("-") && $0 != port }) ?? value
        if target.contains("@") {
            let pieces = target.split(separator: "@", maxSplits: 1).map(String.init)
            username = pieces.first ?? username
            address = pieces.dropFirst().first ?? address
        } else {
            address = target
        }
        serverType = .sftp
        App.notificationManager.showInformationMessage("Remote fields filled")
    }

    private func pasteConnectionString() {
        parseConnectionString(UIPasteboard.general.string ?? "")
    }

    private func validateFields() {
        if address.isEmpty {
            App.notificationManager.showWarningMessage("Address is missing.")
            focusedField = .address
        } else if username.isEmpty {
            App.notificationManager.showWarningMessage("Username is missing.")
            focusedField = .username
        } else if !usesPrivateKey && password.isEmpty {
            App.notificationManager.showWarningMessage("Password or key auth is required.")
            focusedField = .password
        } else if usesPrivateKey && privateKeyContent.isEmpty {
            App.notificationManager.showWarningMessage("Private key content is missing.")
            focusedField = .privateKeyContent
        } else {
            App.notificationManager.showInformationMessage("Remote fields look ready")
        }
    }

    func connect() {
        guard !address.isEmpty else {
            App.notificationManager.showErrorMessage("Address cannot be empty.")
            focusedField = .address
            return
        }

        guard !username.isEmpty else {
            App.notificationManager.showErrorMessage("Username cannot be empty.")
            focusedField = .username
            return
        }

        guard !password.isEmpty || usesPrivateKey else {
            App.notificationManager.showErrorMessage("Password cannot be empty.")
            focusedField = .password
            return
        }

        guard
            let url = URL(
                string: serverType.rawValue.lowercased() + "://" + address + ":\(port)")
        else {
            App.notificationManager.showErrorMessage("Invalid address.")
            focusedField = .address
            return
        }

        let privateKeyContentKeyChainId = UUID().uuidString
        let cred = URLCredential(
            user: username, password: password, persistence: .none)
        let remoteHost = RemoteHost(
            url: url.absoluteString,
            useKeyAuth: false,
            privateKeyContentKeychainID: usesPrivateKey ? privateKeyContentKeyChainId : nil,
            jumpServerUrl: usesJumpServer ? jumpServerUrl : nil
        )

        if usesPrivateKey {
            KeychainAccessor.shared.storeObject(
                for: privateKeyContentKeyChainId, value: privateKeyContent)
        }

        Task {
            do {
                try await onConnectToHostWithCredentials(remoteHost, cred)
                if saveAddress {
                    onSaveHost(remoteHost)
                }
                if saveAddress && saveCredentials {
                    try onSaveCredentialsForHost(remoteHost, cred)
                }
                resetAllFields()
            } catch {
                KeychainAccessor.shared.removeObjectForKey(for: privateKeyContentKeyChainId)
            }
        }
    }

    var body: some View {
        Section(
            header:
                Text("New remote")
                .foregroundColor(Color(id: "sideBarSectionHeader.foreground"))
        ) {
            RemoteSetupHeader(serverType: serverType, usesPrivateKey: usesPrivateKey, savesCredentials: saveCredentials)

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    RemoteQuickButton(title: "Paste SSH", systemImage: "doc.on.clipboard", action: pasteConnectionString)
                    RemoteQuickButton(title: "Check", systemImage: "checkmark.seal", action: validateFields)
                    RemoteQuickButton(title: "Clear", systemImage: "xmark.circle", action: resetAllFields)
                }
                Label {
                    Text(connectionPreview)
                } icon: {
                    Image(systemName: "terminal")
                }
                    .font(.caption.weight(.semibold))
                    .foregroundColor(Color(id: "tab.inactiveForeground"))
                    .lineLimit(1)
            }
            .padding(12)
            .background(Color(id: "sideBar.background").opacity(0.42), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .appCodeGlassPanel(cornerRadius: 14, interactive: false)

            Group {
                HStack {
                    Image(systemName: "rectangle.connected.to.line.below")
                        .foregroundColor(.gray)
                        .font(.subheadline)

                    Picker("Protocol", selection: $serverType) {
                        ForEach(RemoteType.allCases, id: \.self) { type in
                            if type == .sftp {
                                Text("SSH")
                            } else {
                                Text(type.rawValue.uppercased())
                            }
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    Spacer()
                }.frame(maxHeight: 20)

                Group {
                    HStack {
                        Image(systemName: "link")
                            .foregroundColor(.gray)
                            .font(.subheadline)

                        TextField("Address", text: $address)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .textContentType(.URL)
                            .focused($focusedField, equals: .address)
                    }

                    HStack {
                        Image(systemName: "network")
                            .foregroundColor(.gray)
                            .font(.subheadline)

                        TextField("Port", text: $port)
                            .focused($focusedField, equals: .port)
                            .keyboardType(.numberPad)
                    }

                    HStack {
                        Image(systemName: "person")
                            .foregroundColor(.gray)
                            .font(.subheadline)

                        TextField("Username", text: $username)
                            .focused($focusedField, equals: .username)
                            .disableAutocorrection(true)
                            .autocapitalization(.none)
                    }

                    if usesPrivateKey {
                        HStack {
                            Image(systemName: "key")
                                .foregroundColor(.gray)
                                .font(.subheadline)

                            TextEditorWithPlaceholder(
                                placeholder:
                                    "remote.private_key_content",
                                text: $privateKeyContent,
                                customFont: .custom("Menlo", size: 13, relativeTo: .footnote)
                            )
                            .focused($focusedField, equals: .privateKeyContent)
                            .disableAutocorrection(true)
                            .autocapitalization(.none)

                        }.frame(height: 300)

                        Button(action: {
                            showFileImporter.toggle()
                        }) {
                            Text("remote.import_from_file")
                                .font(.footnote)
                                .foregroundColor(.blue)
                        }
                        .fileImporter(
                            isPresented: $showFileImporter, allowedContentTypes: [.data]
                        ) { result in
                            guard let url = try? result.get(),
                                url.startAccessingSecurityScopedResource(),
                                let keyFileContent = try? String(contentsOfFile: url.path)
                            else {
                                App.notificationManager.showErrorMessage(
                                    "errors.failed_to_import_key")
                                return
                            }
                            url.stopAccessingSecurityScopedResource()
                            privateKeyContent = keyFileContent
                        }
                        .frame(maxWidth: .infinity)
                    }

                    HStack {
                        Image(systemName: "key")
                            .foregroundColor(.gray)
                            .font(.subheadline)

                        SecureField(
                            usesPrivateKey ? "Key passphrase" : "Password",
                            text: $password
                        )
                        .focused($focusedField, equals: .password)
                    }

                }
            }
            .padding(7)
            .background(Color.init(id: "input.background"))
            .cornerRadius(10)

            if usesPrivateKey {
                DescriptionText(
                    "remote.setup_note"
                )
            }

            Button(action: {
                App.safariManager.showSafari(
                    url: URL(
                        string:
                            "https://code.thebaselab.com/guides/connecting-to-a-remote-server-ssh-ftp#set-up-your-remote-server"
                    )!)
            }) {
                Text("remote.setup_remote_server")
                    .font(.footnote)
                    .foregroundColor(.blue)
            }

            if serverType == .sftp {
                Toggle("Use Key Authentication", isOn: $usesPrivateKey)
                Toggle("remote.use_jump_server", isOn: $usesJumpServer)
                    .disabled(jumpServerUrl == nil)
            }

            if usesJumpServer {
                HStack {
                    Image(systemName: "rectangle.connected.to.line.below")
                        .foregroundColor(.gray)
                        .font(.subheadline)

                    Picker("remote.jump_using", selection: $jumpServerUrl) {
                        ForEach(hostsSuitableForJumphost, id: \.url) { host in
                            Text(host.rowDisplayName)
                                .tag(host.url as String?)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    Spacer()
                }.frame(maxHeight: 20)
            }

            Toggle("Remember address", isOn: $saveAddress)

            if App.deviceSupportsBiometricAuth {
                Toggle("Remember credentials", isOn: $saveCredentials)
            }

            if saveCredentials {
                DescriptionText(
                    "credentials.note"
                )
            }

            SidebarActionButton(title: "Connect", systemImage: "bolt.horizontal.circle.fill", isPrimary: true) {
                if usesPrivateKey && privateKeyContent.isEmpty {
                    focusedField = .privateKeyContent
                } else {
                    connect()
                }
            }

        }.onChange(of: serverType) { value in
            if value == .sftp {
                port = "22"
            } else {
                usesPrivateKey = false
                port = "21"
            }
        }
        .onChange(of: saveAddress) { value in
            if !value {
                saveCredentials = false
            }
        }
        .onAppear {
            jumpServerUrl = hostsSuitableForJumphost.first?.url
        }
    }
}

private struct RemoteQuickButton: View {
    let title: LocalizedStringKey
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundColor(Color("T1"))
                .lineLimit(1)
                .padding(.horizontal, 9)
                .padding(.vertical, 7)
                .background(Color(id: "button.background").opacity(0.30), in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct RemoteSetupHeader: View {
    let serverType: RemoteType
    let usesPrivateKey: Bool
    let savesCredentials: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "rectangle.connected.to.line.below")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color(id: "activityBar.foreground"))
                    .frame(width: 40, height: 40)
                    .background(Color(id: "button.background").opacity(0.34), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                VStack(alignment: .leading, spacing: 3) {
                    Text("Remote Setup")
                        .font(.headline)
                        .foregroundColor(Color("T1"))
                    Text("Add the host, choose authentication, then connect and save it for later.")
                        .font(.caption)
                        .foregroundColor(Color(id: "tab.inactiveForeground"))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 84), spacing: 7)], alignment: .leading, spacing: 7) {
                RemoteSetupPill(title: serverType == .sftp ? "SSH" : serverType.rawValue.uppercased(), systemImage: "network")
                RemoteSetupPill(title: usesPrivateKey ? "Key Auth" : "Password", systemImage: usesPrivateKey ? "key" : "lock")
                RemoteSetupPill(title: savesCredentials ? "Saved" : "Session", systemImage: savesCredentials ? "checkmark.seal" : "clock")
            }
        }
        .padding(14)
        .background(Color(id: "sideBar.background").opacity(0.58), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .appCodeGlassPanel(cornerRadius: 18, interactive: false)
    }
}

private struct RemoteSetupPill: View {
    let title: String
    let systemImage: String

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .foregroundColor(Color("T1"))
            .lineLimit(1)
            .minimumScaleFactor(0.78)
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(Color(id: "button.background").opacity(0.30), in: Capsule())
    }
}
