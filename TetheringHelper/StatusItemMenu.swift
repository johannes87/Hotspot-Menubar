//
//  StatusItemMenu.swift
//  TetheringHelper
//
//  Created by Johannes Bittner on 29.11.19.
//  Copyright © 2019 Johannes Bittner. All rights reserved.
//

import Cocoa
import UserNotifications // TODO: remove

class StatusItemMenu {
    let androidConnector: AndroidConnector

    var menu: NSMenu!
    private var dataStatisticsMenuItem: NSMenuItem!
    private var pairMenuItem: NSMenuItem!


    private static let dataStatisticsMenuItemTitle = NSLocalizedString(
        "Data used: %.2f MB",
        comment: "amount of data used, shown in status item menu")

    private static let pairMenuItemUnpairedTitle = NSLocalizedString(
        "Pair with phone...",
        comment: "shown in status item menu when not paired yet")

    init(_ androidConnector: AndroidConnector) {
        self.androidConnector = androidConnector
        createMenu()
    }

    private func createMenu() {
        menu = NSMenu(title: "")

        dataStatisticsMenuItem = NSMenuItem(
            title: String(
                format: StatusItemMenu.dataStatisticsMenuItemTitle,
                0.0),
            action: #selector(showDataStatistics(sender:)),
            keyEquivalent: "")
        dataStatisticsMenuItem.target = self

        pairMenuItem = NSMenuItem(
            title: StatusItemMenu.pairMenuItemUnpairedTitle,
            action: #selector(self.androidConnector.pair(sender:)),
            keyEquivalent: "")
        pairMenuItem?.target = self.androidConnector

        let fooMenuItem = NSMenuItem(
            title: "foo",
            action: #selector(foo(sender:)),
            keyEquivalent: "")
        fooMenuItem.target = self


        menu.autoenablesItems = false
        menu.insertItem(dataStatisticsMenuItem, at: 0)
        menu.insertItem(NSMenuItem.separator(), at: 1)
        menu.insertItem(pairMenuItem!, at: 2)
        menu.insertItem(fooMenuItem, at: 3)
    }

    // create user notification for macos 10.14+
    @IBAction private func foo(sender: Any) {
        let content = UNMutableNotificationContent()
        content.title = "Weekly Staff Meeting"
        content.body = "Every Tuesday at 2pm"
        
        let uuidString = UUID().uuidString
        let request = UNNotificationRequest(identifier: uuidString, content: content, trigger: nil)

        let notificationCenter = UNUserNotificationCenter.current()

        notificationCenter.add(request) { (error) in
            if error != nil {
                print("notifaction center error: \(String(describing: error))")
                // Handle any errors.
            }
        }
    }

    @IBAction private func showDataStatistics(sender: Any) {
        print("show data statistics")

    }
}
