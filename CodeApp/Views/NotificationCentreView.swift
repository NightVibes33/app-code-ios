//
//  NotificationCentreView.swift
//  Code App
//
//  Created by Ken Chung on 5/12/2020.
//

import SwiftUI
import UIKit

struct NotificationCentreView: View {

    @EnvironmentObject var App: MainApp

    var body: some View {
        VStack(spacing: 10) {
            ForEach(App.notificationManager.notifications.indices, id: \.self) { i in
                if !App.notificationManager.notifications[i].isRemoved
                    && (App.notificationManager.notifications[i].isPresented
                        || App.notificationManager.isShowingAllBanners)
                {
                    withAnimation(.spring()) {
                        App.notificationManager.notifications[i].data.makeView(
                            isPresented: $App.notificationManager.notifications[i].isPresented,
                            isRemoved: $App.notificationManager.notifications[i].isRemoved)
                    }
                }
            }
        }
    }
}

private struct NotificationItem<V: View>: View {
    let data: NotificationData
    let children: () -> V

    init(
        data: NotificationData,
        @ViewBuilder children: @escaping () -> V = { EmptyView() }
    ) {
        self.data = data
        self.children = children
    }

    var body: some View {
        VStack {
            HStack {
                data.level.icon
                Text(data.title)
                    .lineLimit(5)
                    .font(.subheadline)
                    .foregroundColor(Color.init("T1"))
                Spacer()
            }
            children()
        }
        .frame(minHeight: 50)
        .padding(10)
        .frame(maxWidth: 300)
        .background(Color.init(id: "sideBar.background").opacity(0.78))
        .cornerRadius(10)
        .appCodeGlassPanel(cornerRadius: 14, interactive: true)
    }
}

private struct SimpleNotificationItem: View {

    let data: NotificationData
    @Binding var isPresented: Bool
    @Binding var isRemoved: Bool

    private func copyMessage() {
        UIPasteboard.general.string = data.title
    }

    var body: some View {
        NotificationItem(data: data) {
            HStack {
                Spacer()
                if data.level == .error {
                    NotificationActionButton(title: "Copy", systemImage: "doc.on.doc", action: copyMessage)
                }
                NotificationActionButton(title: "Dismiss", systemImage: "xmark") {
                    withAnimation { isRemoved = true }
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
                withAnimation {
                    isPresented = false
                }
            }
        }
    }
}

private struct NotificationItemWtihProgress: View {

    let data: NotificationData
    @Binding var isPresented: Bool
    @Binding var isRemoved: Bool

    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    var body: some View {
        NotificationItem(data: data) {
            VStack {
                ProgressView(data.progress!)
                    .progressViewStyle(LinearProgressViewStyle())
            }.padding(.top, 4)
        }
        .onTapGesture {
            withAnimation {
                isRemoved = true
            }
        }
        .onReceive(timer) { _ in
            if data.progress!.isCancelled || data.progress!.isFinished {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation {
                        isRemoved = true
                    }
                }
            }
        }
    }
}

private struct AsyncProgressNotificationItem: View {

    let data: NotificationData

    @Binding var isPresented: Bool

    var body: some View {
        NotificationItem(data: data) {
            VStack {
                InfinityProgressView(enabled: true)
            }
        }
        .onAppear {
            Task {
                await data.task?()
                await MainActor.run {
                    isPresented = false
                }
            }
        }

    }

}

private struct NotificationItemWithButton: View {

    let data: NotificationData
    @Binding var isPresented: Bool
    @Binding var isRemoved: Bool

    var body: some View {
        NotificationItem(data: data) {
            VStack(alignment: .leading, spacing: 8) {
                if data.secondaryAction == nil {
                    Text(
                        String(
                            format: NSLocalizedString("notification.source", comment: ""),
                            (data.source ?? ""))
                    )
                    .lineLimit(2)
                    .font(.system(size: 12))
                    .foregroundColor(Color.gray)
                }

                HStack {
                    Spacer()
                    if data.primaryAction != nil {
                        NotificationActionButton(title: LocalizedStringKey(data.primaryTitle), systemImage: "arrow.right.circle") {
                            data.primaryAction?()
                            withAnimation { isRemoved = true }
                        }
                    }
                    if data.secondaryAction != nil {
                        NotificationActionButton(title: LocalizedStringKey(data.secondaryTitle), systemImage: "arrow.triangle.2.circlepath") {
                            data.secondaryAction?()
                            withAnimation { isRemoved = true }
                        }
                    }
                    NotificationActionButton(title: "common.cancel", systemImage: "xmark") {
                        withAnimation { isRemoved = true }
                    }
                }
            }
        }
    }
}


private struct NotificationActionButton: View {
    let title: LocalizedStringKey
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .labelStyle(.titleAndIcon)
                .foregroundColor(.white)
                .lineLimit(1)
                .font(.system(size: 12, weight: .semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color.init(id: "statusBar.background"), in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

extension NotificationData.Level {
    var icon: some View {
        switch self {
        case .error:
            return Image(systemName: "xmark.circle.fill").font(.subheadline)
                .foregroundColor(Color.red)
        case .info:
            return Image(systemName: "info.circle.fill").font(.subheadline)
                .foregroundColor(Color.blue)
        case .warning:
            return Image(systemName: "exclamationmark.triangle.fill").font(.subheadline)
                .foregroundColor(Color.yellow)
        case .success:
            return Image(systemName: "checkmark.circle.fill").font(.subheadline)
                .foregroundColor(Color.green)
        }
    }
}

extension NotificationData {
    func makeView(isPresented: Binding<Bool>, isRemoved: Binding<Bool>) -> some View {
        switch style {
        case .progress:
            return AnyView(
                NotificationItemWtihProgress(
                    data: self, isPresented: isPresented, isRemoved: isRemoved))
        case .basic:
            return AnyView(
                SimpleNotificationItem(data: self, isPresented: isPresented, isRemoved: isRemoved))
        case .action:
            return AnyView(
                NotificationItemWithButton(
                    data: self, isPresented: isPresented, isRemoved: isRemoved))
        case .infinityProgress:
            return AnyView(
                AsyncProgressNotificationItem(data: self, isPresented: isPresented)
            )
        }
    }
}
