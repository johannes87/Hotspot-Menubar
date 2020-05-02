//
//  StatusItemMenu.swift
//  TetheringHelper
//
//  Created by Johannes Bittner on 29.11.19.
//  Copyright © 2019 Johannes Bittner. All rights reserved.
//

import Cocoa

class StatusItemMenu: NSObject, NSMenuItemValidation {
    private static let dataStatisticsMenuItemTitle = NSLocalizedString(
        "Data used: %.2f MB",
        comment: "amount of data used, shown in status item menu")
    private static let pairMenuItemUnpairedTitle = NSLocalizedString(
        "Not paired, searching...",
        comment: "shown in status item menu when not paired yet")
    private static let pairMenuItemPairedTitle = NSLocalizedString(
        "Paired with %@",
        comment: "shown in status item menu when paired")
    private static let quitMenuItemTitle = NSLocalizedString(
        "Quit",
        comment: "menu item for quitting the application")

    var menu: NSMenu!

    private var dataStatisticsMenuItem: NSMenuItem!
    private var pairMenuItem: NSMenuItem!
    private var quitMenuItem: NSMenuItem!

    private var pairingStatus = PairingStatus.unpaired


    override init() {
        super.init()
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

        // pairMenuItem is for information only, so it's disabled (action=nil)
        pairMenuItem = NSMenuItem(
            title: StatusItemMenu.pairMenuItemUnpairedTitle,
            action: nil,
            keyEquivalent: "")

        quitMenuItem = NSMenuItem(
            title: StatusItemMenu.quitMenuItemTitle,
            action: #selector(quitApplication(sender:)),
            keyEquivalent: "")
        quitMenuItem.target = self

        menu.insertItem(dataStatisticsMenuItem, at: 0)
        menu.insertItem(pairMenuItem, at: 1)
        menu.insertItem(NSMenuItem.separator(), at: 2)
        menu.insertItem(quitMenuItem, at: 3)
    }

    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        return true
    }

    func setPairingStatus(pairingStatus: PairingStatus) {
        self.pairingStatus = pairingStatus
        updatePairMenuItemTitle()
    }

    private func updatePairMenuItemTitle() {
        // UI needs to be updated in main loop
        DispatchQueue.main.async {
            switch self.pairingStatus {
            case .paired(let phoneName):
                self.pairMenuItem.title = String(format: StatusItemMenu.pairMenuItemPairedTitle, phoneName)
            case .unpaired:
                self.pairMenuItem.title = StatusItemMenu.pairMenuItemUnpairedTitle
            }
        }
    }

    @IBAction private func showDataStatistics(sender: Any) {
        print("show data statistics")
    }

    @IBAction private func quitApplication(sender: Any) {
        NSApp.terminate(nil)
    }
}
