//
//  StatusItemMenu.swift
//  TetheringHelper
//
//  Created by Johannes Bittner on 29.11.19.
//  Copyright © 2019 Johannes Bittner. All rights reserved.
//

import Cocoa

class StatusItemMenu: NSObject, NSMenuItemValidation, StatusItemMenuDelegate {
    private static let dataStatisticsMenuItemTitle = NSLocalizedString(
        "Data used: %.2f MB",
        comment: "amount of data used, shown in status item menu")
    private static let pairMenuItemUnpairedTitle = NSLocalizedString(
        "Not paired, searching...",
        comment: "shown in status item menu when not paired yet")
    private static let pairMenuItemPairedTitle = NSLocalizedString(
        "Paired with %@",
        comment: "shown in status item menu when paired")
    private static let preferencesMenuItemTitle = NSLocalizedString(
        "Preferences...",
        comment: "menu item in menubar for showing preferences window")
    private static let aboutMenuItemTitle = NSLocalizedString(
        "About TetheringHelper",
        comment: "menu item in menubar for showing about window")
    private static let quitMenuItemTitle = NSLocalizedString(
        "Quit",
        comment: "menu item for quitting the application")

    // `menu` is non-private because it needs to be accessed from StatusItem.swift
    var menu: NSMenu!

    private var dataStatisticsMenuItem: NSMenuItem!
    private var pairMenuItem: NSMenuItem!
    private var preferencesMenuItem: NSMenuItem!
    private var aboutMenuItem: NSMenuItem!
    private var quitMenuItem: NSMenuItem!

    private var preferencesWindowController: NSWindowController!


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

        // pairMenuItem is for information only, so it's disabled (action=nil and no target)
        pairMenuItem = NSMenuItem(
            title: StatusItemMenu.pairMenuItemUnpairedTitle,
            action: nil,
            keyEquivalent: "")

        preferencesMenuItem = NSMenuItem(
            title: StatusItemMenu.preferencesMenuItemTitle,
            action: #selector(showPreferencesWindow(sender:)),
            keyEquivalent: ",")
        preferencesMenuItem.target = self

        aboutMenuItem = NSMenuItem(
            title: StatusItemMenu.aboutMenuItemTitle,
            action: #selector(showAboutWindow(sender:)),
            keyEquivalent: "")
        aboutMenuItem.target = self

        quitMenuItem = NSMenuItem(
            title: StatusItemMenu.quitMenuItemTitle,
            action: #selector(quitApplication(sender:)),
            keyEquivalent: "q")
        quitMenuItem.target = self

        menu.insertItem(dataStatisticsMenuItem, at: 0)
        menu.insertItem(pairMenuItem, at: 1)
        menu.insertItem(NSMenuItem.separator(), at: 2)
        menu.insertItem(preferencesMenuItem, at: 3)
        menu.insertItem(aboutMenuItem, at: 4)
        menu.insertItem(quitMenuItem, at: 5)
    }

    @IBAction private func showDataStatistics(sender: Any) {
        // TODO: implement showDataStatistics
        print("show data statistics")
    }

    @IBAction private func showPreferencesWindow(sender: Any) {
        if preferencesWindowController == nil {
            let storyboard = NSStoryboard(name: "PreferencesWindow", bundle: nil)
            preferencesWindowController = storyboard.instantiateInitialController() as? NSWindowController
        }
        preferencesWindowController!.showWindow(sender)
    }

    @IBAction private func showAboutWindow(sender: Any) {
        // TODO: implement showAboutWindow
        print("show about window")
    }

    @IBAction private func quitApplication(sender: Any) {
        NSApp.terminate(sender)
    }

    // MARK: NSMenuItemValidation
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        return true
    }

    // MARK: StatusItemMenuDelegate
    func sessionBytesTransferredUpdated(bytesTransferred: UInt64) {
        // TODO: see TODO in pairingStatusUpdated
        DispatchQueue.main.async {
            let megabytesTransferred = Double(bytesTransferred) / 1024 / 1024
            self.dataStatisticsMenuItem.title = String(format: StatusItemMenu.dataStatisticsMenuItemTitle, megabytesTransferred)
        }
    }

    func pairingStatusUpdated(pairingStatus: PairingStatus) {
        // UI needs to be updated in main loop
        // TODO: it also works without, why?! :/
        DispatchQueue.main.async {
            if let phoneName = pairingStatus.phoneName {
                self.pairMenuItem.title = String(format: StatusItemMenu.pairMenuItemPairedTitle, phoneName)
            } else {
                self.pairMenuItem.title = StatusItemMenu.pairMenuItemUnpairedTitle
            }
        }
    }
}
