//
//  ExtensionCommunicationHelper.swift
//  Code
//
//  Created by Ken Chung on 29/04/2024.
//

import Foundation

class ExtensionCommunicationHelper {
    static let containerURL = FileManager.default.containerURL(
        forSecurityApplicationGroupIdentifier: "group.app.ish.iSH.39A8Q3T3TR")

    static func writeToStdin(data: String) {
        let coordinator = NSFileCoordinator(filePresenter: nil)
        let string = data

        var error: NSError?
        let sharedURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.app.ish.iSH.39A8Q3T3TR")!
        coordinator.coordinate(
            writingItemAt: sharedURL.appendingPathComponent("stdin"), options: .forReplacing,
            error: &error,
            byAccessor: { url in
                try? string.write(to: url, atomically: true, encoding: .utf8)

                let notificationName = CFNotificationName(
                    "com.nightvibes.appcode.node.stdin" as CFString)
                let notificationCenter = CFNotificationCenterGetDarwinNotifyCenter()
                CFNotificationCenterPostNotification(
                    notificationCenter, notificationName, nil, nil, false)
            })
    }

    static func writeToStdout(data: String) {
        let coordinator = NSFileCoordinator(filePresenter: nil)
        let string = data

        var error: NSError?
        let sharedURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.app.ish.iSH.39A8Q3T3TR")!
        coordinator.coordinate(
            writingItemAt: sharedURL.appendingPathComponent("stdout"), options: .forReplacing,
            error: &error,
            byAccessor: { url in
                try? string.write(to: url, atomically: true, encoding: .utf8)

                let notificationName = CFNotificationName(
                    "com.nightvibes.appcode.node.stdout" as CFString)
                let notificationCenter = CFNotificationCenterGetDarwinNotifyCenter()
                CFNotificationCenterPostNotification(
                    notificationCenter, notificationName, nil, nil, false)
            })
    }
}
