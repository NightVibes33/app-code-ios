//
//  UserDefaults+Hosts.swift
//  Code
//
//  Created by Ken Chung on 1/5/2022.
//

import Foundation

private enum AppCodeSyncedSettings {
    static let remoteHostsKey = "remote.hosts"

    static func syncFromCloudIfNeeded() {}

    static func mirrorRemoteHosts(_ data: Data) {}
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
