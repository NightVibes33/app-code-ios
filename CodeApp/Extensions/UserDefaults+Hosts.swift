//
//  UserDefaults+Hosts.swift
//  Code
//
//  Created by Ken Chung on 1/5/2022.
//

import Foundation

private enum AppCodeSyncedSettings {
    static let remoteHostsKey = "remote.hosts"
    static let syncEnabledKey = "appcode.settingsSyncEnabled"

    static var isEnabled: Bool {
        UserDefaults.standard.object(forKey: syncEnabledKey) as? Bool ?? true
    }

    static func syncFromCloudIfNeeded() {
        guard isEnabled else { return }
        let store = NSUbiquitousKeyValueStore.default
        store.synchronize()
        if UserDefaults.standard.data(forKey: remoteHostsKey) == nil,
            let cloudData = store.data(forKey: remoteHostsKey)
        {
            UserDefaults.standard.set(cloudData, forKey: remoteHostsKey)
        }
    }

    static func mirrorRemoteHosts(_ data: Data) {
        guard isEnabled else { return }
        let store = NSUbiquitousKeyValueStore.default
        store.set(data, forKey: remoteHostsKey)
        store.synchronize()
    }
}

extension UserDefaults {
    var remoteHosts: [RemoteHost] {
        get {
            AppCodeSyncedSettings.syncFromCloudIfNeeded()
            if let data = self.data(forKey: AppCodeSyncedSettings.remoteHostsKey),
                let array = try? PropertyListDecoder().decode([RemoteHost].self, from: data)
            {
                return array
            } else {
                return []
            }
        }
        set {
            if let data = try? PropertyListEncoder().encode(newValue) {
                self.set(data, forKey: AppCodeSyncedSettings.remoteHostsKey)
                AppCodeSyncedSettings.mirrorRemoteHosts(data)
            }
        }
    }
    var gitCredentialsLookupEntries: [GitCredentials] {
        get {
            if let data = self.data(forKey: "git.credentials.entries"),
                let array = try? PropertyListDecoder().decode(
                    [GitCredentials].self, from: data)
            {
                return array
            } else {
                return []
            }
        }
        set {
            if let data = try? PropertyListEncoder().encode(newValue) {
                self.set(data, forKey: "git.credentials.entries")
            }
        }
    }
}
