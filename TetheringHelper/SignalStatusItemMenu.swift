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

    private var dataUsedMB = 0.0

    private static let dataStatisticsMenuItemTitle = NSLocalizedString(
        "Data used: %.2f MB",
        comment: "amount of data used, shown in status item menu")

    private static let pairMenuItemUnpairedTitle = NSLocalizedString(
        "Pair with phone...",
        comment: "status item menu item title when phone is not paired yet")

    private var dataStatisticsMenuItem = NSMenuItem(
        title: String(format: dataStatisticsMenuItemTitle, 0.0),
        action: #selector(showDataStatistics(sender:)),
        keyEquivalent: "")


    private var pairMenuItem = NSMenuItem(
        title: pairMenuItemUnpairedTitle,
        action: #selector(pairPhone(sender:)),
        keyEquivalent: "")

    init() {
        menu = NSMenu(title: "")
        menu.autoenablesItems = false

        dataStatisticsMenuItem.target = self
        menu.insertItem(dataStatisticsMenuItem, at: 0)

        menu.insertItem(NSMenuItem.separator(), at: 1)

        pairMenuItem.target = self
        menu.insertItem(pairMenuItem, at: 2)
    }

    @IBAction private func showDataStatistics(sender: Any) {
        print("show data statistics")
        dataUsedMB += 1.0 // TODO remove
        dataStatisticsMenuItem.title = String(
            format: SignalStatusItemMenu.dataStatisticsMenuItemTitle,
            dataUsedMB)
    }

    @IBAction private func pairPhone(sender: Any) {
        print("pair phone action")
    }
}
