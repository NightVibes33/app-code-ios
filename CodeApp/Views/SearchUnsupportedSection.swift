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
                Text("Global search is unavailable while connected to a remote workspace.")
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
