//
//  panel.swift
//  Code App
//
//  Created by Ken Chung on 5/12/2020.
//

import SwiftUI
import ios_system

private let PANEL_MINIMUM_HEIGHT: CGFloat = 72
private let TOP_BAR_HEIGHT: CGFloat = 40
private let EDITOR_MINIMUM_HEIGHT: CGFloat = 8
private let BOTTOM_BAR_HEIGHT: CGFloat = 20

struct PanelToolbarButton: View {
    let systemName: String
    let onTapGesture: () -> Void

    var body: some View {
        Button(action: onTapGesture) {
            Image(systemName: systemName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color.init(id: "panelTitle.activeForeground"))
                .frame(width: 28, height: 28)
                .background(Color(id: "button.background").opacity(0.28), in: Circle())
                .contentShape(Circle())
                .hoverEffect(.highlight)
                .padding(.horizontal, 4)
        }
    }
}

private struct PanelTabLabel: View {
    let panel: Panel
    @SceneStorage("panel.focusedId") var currentPanelId: String = DefaultUIState.PANEL_FOCUSED_ID

    var body: some View {
        Button {
            currentPanelId = panel.labelId
        } label: {
            Text(LocalizedStringKey(panel.labelId))
                .textCase(.uppercase)
                .foregroundColor(
                    Color.init(
                        id: panel.labelId == currentPanelId
                            ? "panelTitle.activeForeground" : "panelTitle.inactiveForeground")
                )
                .font(.system(size: 12, weight: panel.labelId == currentPanelId ? .semibold : .regular))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(id: "button.background").opacity(panel.labelId == currentPanelId ? 0.26 : 0), in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct PanelTabs: View {
    @EnvironmentObject var panelManager: PanelManager

    var body: some View {
        ForEach(panelManager.panels, id: \.labelId) { panel in
            PanelTabLabel(panel: panel)

            if let bubbleCount = panelManager.bubbleCount[panel.labelId] {
                Circle()
                    .fill(Color.init(id: "panel.border"))
                    .frame(width: 14, height: 14)
                    .overlay(
                        Text("\(bubbleCount)")
                            .foregroundColor(Color.init(id: "panelTitle.activeForeground"))
                            .font(.system(size: 10))
                    )
            }
        }
    }

}

private struct Implementation: View {

    @EnvironmentObject var panelManager: PanelManager
    @SceneStorage("panel.focusedId") var currentPanelId: String = DefaultUIState.PANEL_FOCUSED_ID

    var currentPanel: Panel? {
        panelManager.panels.first(where: { $0.labelId == currentPanelId })
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Rectangle()
                    .frame(minWidth: 0, maxWidth: .infinity, maxHeight: 1)
                    .foregroundColor(
                        Color.init(id: "panel.border"))
            }

            HStack {
                PanelTabs()

                Spacer()

                currentPanel?
                    .toolBarView
                    .padding(.horizontal)
                    .environmentObject(panelManager)

            }
            .frame(height: 32)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)

            HStack {
                if let currentPanel = currentPanel {
                    currentPanel.mainView
                        .padding(.horizontal)
                } else {
                    Text("Empty Panel")
                }
            }.frame(maxHeight: .infinity)
        }
        .foregroundColor(Color(id: "panelTitle.activeForeground"))
        .font(.system(size: 12, weight: .regular))
        .background(Color.init(id: "editor.background").opacity(0.96))
    }

}

struct PanelView: View {

    @EnvironmentObject var App: MainApp

    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    @SceneStorage("panel.visible") var showsPanel: Bool = DefaultUIState.PANEL_IS_VISIBLE
    @SceneStorage("panel.height") var panelHeight: Double = DefaultUIState.PANEL_HEIGHT

    @State var showSheet = false
    @GestureState private var translation: CGFloat?

    var maxHeight: CGFloat {
        windowHeight
            - UIApplication.shared.getSafeArea(edge: .top)
            - UIApplication.shared.getSafeArea(edge: .bottom)
            - TOP_BAR_HEIGHT
            - EDITOR_MINIMUM_HEIGHT
            - BOTTOM_BAR_HEIGHT
    }
    var windowHeight: CGFloat

    func evaluateProposedHeight(proposal: CGFloat) {
        if proposal < PANEL_MINIMUM_HEIGHT {
            showsPanel = false
            panelHeight = DefaultUIState.PANEL_HEIGHT
        } else if proposal > maxHeight {
            panelHeight = maxHeight
        } else {
            panelHeight = proposal
        }
    }

    var body: some View {
        if #available(iOS 26.0, *) {
            Implementation()
                .frame(height: min(CGFloat(panelHeight), maxHeight))
                .background(Color.init(id: "editor.background"))
                .gesture(
                    DragGesture(minimumDistance: 10.0, coordinateSpace: .global)
                        .updating($translation) { value, gestureState, transaction in
                            let proposedNewHeight =
                                panelHeight - value.translation.height + (translation ?? 0)
                            evaluateProposedHeight(proposal: proposedNewHeight)
                            gestureState = value.translation.height
                        }
                )
        } else {
            Implementation()
                .frame(height: min(CGFloat(panelHeight), maxHeight))
                .background(Color.init(id: "editor.background"))
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let proposedNewHeight = panelHeight - value.translation.height
                            evaluateProposedHeight(proposal: proposedNewHeight)
                        }
                )
        }
    }
}
