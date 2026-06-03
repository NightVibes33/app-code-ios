//
//  RemoteList.swift
//  Code
//
//  Created by Ken Chung on 11/4/2022.
//

import SwiftUI

struct RemoteListSection: View {

    @EnvironmentObject var App: MainApp

    let hosts: [RemoteHost]
    let onRemoveHost: (RemoteHost, Bool) -> Void
    let onConnectToHost: (RemoteHost) async throws -> Void
    let onRenameHost: (RemoteHost, String) -> Void

    var body: some View {
        Section(
            header:
                Text("Remotes")
                .foregroundColor(Color(id: "sideBarSectionHeader.foreground"))
        ) {
            if hosts.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Image(systemName: "server.rack")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(Color(id: "activityBar.foreground"))
                    Text("No Saved Remotes")
                        .font(.headline)
                        .foregroundColor(Color("T1"))
                    Text("Save SSH or FTP hosts here to reconnect faster.")
                        .font(.caption)
                        .foregroundColor(Color(id: "tab.inactiveForeground"))
                }
                .padding(14)
                .background(Color(id: "sideBar.background").opacity(0.58), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .appCodeGlassPanel(cornerRadius: 18, interactive: false)
            }

            ForEach(hosts, id: \.url) { host in
                RemoteHostCell(
                    host: host,
                    onRemove: {
                        onRemoveHost(host, false)
                    },
                    onConnect: {
                        try await onConnectToHost(host)
                    },
                    onRenameHost: { name in
                        onRenameHost(host, name)
                    }
                )
            }
        }
    }
}
