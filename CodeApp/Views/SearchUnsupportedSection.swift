//
//  SearchUnsupportedSection.swift
//  Code
//
//  Created by Ken Chung on 15/4/2022.
//

import SwiftUI

struct SearchUnsupportedSection: View {
    var body: some View {
        Section(
            header:
                Text("Search")
                .foregroundColor(Color(id: "sideBarSectionHeader.foreground"))
        ) {
            VStack(alignment: .leading, spacing: 9) {
                Image(systemName: "magnifyingglass.circle")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(Color(id: "activityBar.foreground"))
                Text("Search Disabled")
                    .font(.headline)
                    .foregroundColor(Color("T1"))
                Text("Global grep search runs locally, so it is unavailable while connected to a remote workspace. Use the remote shell for grep, or open a local copy of the project to use indexed results here.")
                    .font(.caption)
                    .foregroundColor(Color(id: "tab.inactiveForeground"))
                    .fixedSize(horizontal: false, vertical: true)
                Label("Next step: run grep in Terminal or open a local workspace", systemImage: "terminal")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(Color(id: "activityBar.foreground"))
            }
            .padding(14)
            .background(Color(id: "sideBar.background").opacity(0.58), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .appCodeGlassPanel(cornerRadius: 18, interactive: false)
        }
    }
}
