//
//  UnsupportedSourceControlView.swift
//  Code
//
//  Created by Ken Chung on 12/4/2022.
//

import SwiftUI

struct SourceControlUnsupportedSection: View {
    var body: some View {
        Section(
            header:
                Text("source_control.title")
                .foregroundColor(Color(id: "sideBarSectionHeader.foreground"))
        ) {
            VStack(alignment: .leading, spacing: 9) {
                Image(systemName: "point.topleft.down.curvedto.point.bottomright.up")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(Color(id: "activityBar.foreground"))
                Text("Source Control Disabled")
                    .font(.headline)
                    .foregroundColor(Color("T1"))
                Text("This workspace does not expose a local Git provider.")
                    .font(.caption)
                    .foregroundColor(Color(id: "tab.inactiveForeground"))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .background(Color(id: "sideBar.background").opacity(0.58), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .appCodeGlassPanel(cornerRadius: 18, interactive: false)
        }
    }
}
