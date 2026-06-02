//
//  EmptySourceControlView.swift
//  Code
//
//  Created by Ken Chung on 12/4/2022.
//

import SwiftUI

struct SourceControlEmptySection: View {

    @EnvironmentObject var App: MainApp

    let onInitializeRepository: () async throws -> Void

    var body: some View {
        Section(
            header:
                Text("source_control.title")
                .foregroundColor(Color(id: "sideBarSectionHeader.foreground"))
        ) {
            VStack(alignment: .leading, spacing: 13) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "point.topleft.down.curvedto.point.bottomright.up")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(Color(id: "activityBar.foreground"))
                        .frame(width: 42, height: 42)
                        .background(Color(id: "button.background").opacity(0.34), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("No Git Repository")
                            .font(.headline)
                            .foregroundColor(Color("T1"))
                        Text("Initialize this workspace or clone a remote repo below.")
                            .font(.caption)
                            .foregroundColor(Color(id: "tab.inactiveForeground"))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Button {
                    Task {
                        try await onInitializeRepository()
                    }
                } label: {
                    Label("Initialize Repository", systemImage: "plus.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(Color(id: "button.background"), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityHint("Create a Git repository in the current workspace.")
            }
            .padding(14)
            .background(Color(id: "sideBar.background").opacity(0.58), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .appCodeGlassPanel(cornerRadius: 18, interactive: false)
        }
    }
}
