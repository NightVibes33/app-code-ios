//
//  ActivityBarItemView.swift
//  Code
//
//  Created by Ken Chung on 14/4/2022.
//

import SwiftUI

struct ContextMenuItem {
    let id = UUID()
    let action: () -> Void
    let text: String
    let imageSystemName: String
}

struct ActivityBarIconView: View {

    @EnvironmentObject var activityBarManager: ActivityBarManager
    let activityBarItem: ActivityBarItem

    @SceneStorage("activitybar.selected.item") var activeItemId: String = DefaultUIState
        .ACTIVITYBAR_SELECTED_ITEM
    @SceneStorage("sidebar.visible") var isSideBarVisible: Bool = DefaultUIState.SIDEBAR_VISIBLE

    private var isSelected: Bool {
        activeItemId == activityBarItem.itemID && isSideBarVisible
    }

    var body: some View {
        ZStack(alignment: .leading) {
            if isSelected {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(Color.init(id: "activityBar.foreground"))
                    .frame(width: 3, height: 28)
                    .padding(.leading, 2)
            }

            Button(action: {
                if isSelected {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        isSideBarVisible = false
                    }
                } else {
                    activeItemId = activityBarItem.itemID
                    withAnimation(.easeInOut(duration: 0.18)) {
                        isSideBarVisible = true
                    }
                }
            }) {
                VStack(spacing: 4) {
                    Image(systemName: activityBarItem.iconSystemName)
                        .font(.system(size: 18, weight: isSelected ? .semibold : .regular))
                    Text(activityBarItem.title)
                        .font(.system(size: 9, weight: isSelected ? .semibold : .regular))
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }
                .foregroundColor(
                    Color.init(
                        id: isSelected
                            ? "activityBar.foreground"
                            : "activityBar.inactiveForeground")
                )
                .frame(width: 58, height: 50)
                .background(
                    Color.init(id: "button.background").opacity(isSelected ? 0.42 : 0),
                    in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                )
                .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .hoverEffect(.highlight)
                .frame(maxWidth: .infinity, minHeight: 62.0)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(activityBarItem.title))
            .accessibilityValue(isSelected ? Text("Selected") : Text(""))
            .if(activityBarItem.shortcutKey != nil && activityBarItem.modifiers != nil) { view in
                view
                    .keyboardShortcut(
                        activityBarItem.shortcutKey!, modifiers: activityBarItem.modifiers!)
            }
            .if(activityBarItem.contextMenuItems != nil) { view in
                view
                    .contextMenu {
                        ForEach(activityBarItem.contextMenuItems!(), id: \.id) { item in
                            Button(action: {
                                item.action()
                            }) {
                                Text(item.text)
                                Image(systemName: item.imageSystemName)
                            }
                        }
                    }
            }
            if let bubble = activityBarItem.bubble() {
                switch bubble {
                case let .text(bubbleText):
                    if bubbleText.isEmpty {
                        Circle()
                            .fill(Color.init(id: "statusBar.background"))
                            .frame(width: 10, height: 10)
                            .offset(x: 10, y: -10)
                    } else {
                        ZStack {
                            Text(bubbleText)
                                .font(.system(size: 12))
                        }
                        .padding(.horizontal, 3)
                        .foregroundColor(
                            Color.init(id: "statusBar.foreground")
                        )
                        .background(
                            Color.init(id: "statusBar.background")
                        )
                        .cornerRadius(5)
                        .offset(x: 10, y: -10)
                    }
                case let .systemImage(systemImage):
                    Image(systemName: systemImage)
                        .font(.system(size: 12))
                        .padding(.horizontal, 3)
                        .foregroundColor(
                            Color.init(id: "statusBar.foreground")
                        )
                        .background(
                            Color.init(id: "statusBar.background")
                        )
                        .cornerRadius(5)
                        .offset(x: 10, y: -10)
                }
            }
        }
        .animation(.easeInOut(duration: 0.18), value: isSelected)
    }
}
