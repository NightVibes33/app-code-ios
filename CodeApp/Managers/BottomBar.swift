//
//  bottomBar.swift
//  Code
//
//  Created by Ken Chung on 1/7/2021.
//

import SwiftGit2
import SwiftUI

struct StatusBar: View {
    @EnvironmentObject var App: MainApp
    @EnvironmentObject var statusBarManager: StatusBarManager
    @EnvironmentObject var themeManager: ThemeManager

    var leftMostItems: [StatusBarItem] {
        statusBarManager.items
            .filter { $0.shouldDisplay(App) }
            .filter { $0.positionPreference == .left }
            .sorted { $0.positionPrecedence > $1.positionPrecedence }
    }
    var rightMostItems: [StatusBarItem] {
        statusBarManager.items
            .filter { $0.shouldDisplay(App) }
            .filter { $0.positionPreference == .right }
            .sorted { $0.positionPrecedence < $1.positionPrecedence }
    }

    var body: some View {
        ZStack {
            Color.init(id: "statusBar.background")
            HStack(spacing: 4) {
                ForEach(leftMostItems) { item in
                    item.view
                }
                Spacer()
                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                        App.notificationManager.isShowingAllBanners.toggle()
                    }
                } label: {
                    Label("\(App.notificationManager.activeNotificationCount)", systemImage: "tray.full")
                        .labelStyle(.titleAndIcon)
                        .font(.system(size: 11, weight: .semibold))
                        .padding(.horizontal, 8)
                        .frame(height: 18)
                        .background(Color(id: "button.background").opacity(App.notificationManager.isShowingAllBanners ? 0.42 : 0.16), in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Job Center")

                ForEach(rightMostItems) { item in
                    item.view
                }
            }
            .padding(.horizontal, [UIApplication.shared.getSafeArea(edge: .bottom), 5].max())
        }
        .font(.system(size: 12))
        .foregroundColor(Color.init(id: "statusBar.foreground"))
        .background(Color.init(id: "statusBar.background").opacity(0.72))
        .appCodeGlassPanel(cornerRadius: 0)
    }
}
