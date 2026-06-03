//
//  RemoteConnectedView.swift
//  Code
//
//  Created by Ken Chung on 11/4/2022.
//

import SwiftUI

struct RemoteConnectedSection: View {

    @EnvironmentObject var App: MainApp

    var body: some View {
        Section(
            header:
                Text("Current Remote")
                .foregroundColor(Color(id: "sideBarSectionHeader.foreground"))
        ) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.green)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Connected")
                            .font(.headline)
                            .foregroundColor(Color("T1"))
                        Text(App.workSpaceStorage.remoteHost ?? "Remote server")
                            .font(.caption)
                            .foregroundColor(Color(id: "tab.inactiveForeground"))
                            .lineLimit(2)
                    }
                }

                if let fingerPrint = App.workSpaceStorage.remoteFingerprint {
                    Text("Fingerprint: \(fingerPrint)")
                        .font(.caption2.monospaced())
                        .foregroundColor(Color(id: "tab.inactiveForeground"))
                        .lineLimit(2)
                }

                SidebarActionButton(title: "Disconnect", systemImage: "xmark.circle", isPrimary: false) {
                    App.workSpaceStorage.disconnect()
                }
            }
            .padding(14)
            .background(Color(id: "sideBar.background").opacity(0.58), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .appCodeGlassPanel(cornerRadius: 18, interactive: false)
        }
    }
}
