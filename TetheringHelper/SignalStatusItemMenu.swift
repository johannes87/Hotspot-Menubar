//
//  SignalStatusItemMenu.swift
//  TetheringHelper
//
//  Created by Johannes Bittner on 29.11.19.
//  Copyright © 2019 Johannes Bittner. All rights reserved.
//

import Cocoa

class SignalStatusItemMenu {
    var menu: NSMenu
    unowned let androidConnector: AndroidConnector // TODO: ensure unowned is correct here, no memory leaks

    // TODO: use data statistics class
    private var dataUsedMB = 0.0

    private static let dataStatisticsMenuItemTitle = NSLocalizedString(
        "Data used: %.2f MB",
        comment: "amount of data used, shown in status item menu")

    private static let pairMenuItemUnpairedTitle = NSLocalizedString(
        "Pair with phone...",
        comment: "shown in status item menu when not paired yet")

    private var dataStatisticsMenuItem: NSMenuItem!
    private var pairMenuItem: NSMenuItem!

    init(androidConnector: AndroidConnector) {
        self.androidConnector = androidConnector

        menu = NSMenu(title: "")

        dataStatisticsMenuItem = NSMenuItem(
            title: String(
                format: SignalStatusItemMenu.self.dataStatisticsMenuItemTitle,
                0.0),
            action: #selector(showDataStatistics(sender:)),
            keyEquivalent: "")
        dataStatisticsMenuItem.target = self

        pairMenuItem = NSMenuItem(
            title: SignalStatusItemMenu.pairMenuItemUnpairedTitle,
            action: #selector(androidConnector.pair(sender:)),
            keyEquivalent: "")
        pairMenuItem?.target = androidConnector

        setupMenu()
    }

    private func setupMenu() {
        menu.autoenablesItems = false
        menu.insertItem(dataStatisticsMenuItem, at: 0)
        menu.insertItem(NSMenuItem.separator(), at: 1)
        menu.insertItem(pairMenuItem!, at: 2)
    }
    

    @IBAction private func showDataStatistics(sender: Any) {
        print("show data statistics")
        dataUsedMB += 1.0 // TODO remove
        dataStatisticsMenuItem.title = String(
            format: SignalStatusItemMenu.dataStatisticsMenuItemTitle,
            dataUsedMB)
    }
}
