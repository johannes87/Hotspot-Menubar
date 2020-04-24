//
//  StatusItemMenu.swift
//  TetheringHelper
//
//  Created by Johannes Bittner on 29.11.19.
//  Copyright © 2019 Johannes Bittner. All rights reserved.
//

import Cocoa

class StatusItemMenu {
    private static let dataStatisticsMenuItemTitle = NSLocalizedString(
        "Data used: %.2f MB",
        comment: "amount of data used, shown in status item menu")
    private static let pairMenuItemUnpairedTitle = NSLocalizedString(
        "Pair with phone...",
        comment: "shown in status item menu when not paired yet")

    let androidConnector: AndroidConnector

    var menu: NSMenu!
    private var dataStatisticsMenuItem: NSMenuItem!
    private var pairMenuItem: NSMenuItem!


    init(androidConnector: AndroidConnector) {
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

        menu.autoenablesItems = false
        menu.insertItem(dataStatisticsMenuItem, at: 0)
        menu.insertItem(NSMenuItem.separator(), at: 1)
        menu.insertItem(pairMenuItem!, at: 2)
    }

    @IBAction private func showDataStatistics(sender: Any) {
        print("show data statistics")

    }
}
