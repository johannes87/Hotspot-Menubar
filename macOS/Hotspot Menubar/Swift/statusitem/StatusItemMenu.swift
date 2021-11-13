//
//  StatusItemMenu.swift
//  Hotspot Menubar
//
//  Created by Johannes Bittner on 29.11.19.
//  Copyright © 2019 Johannes Bittner. All rights reserved.
//

import Cocoa

class StatusItemMenu: NSObject, StatusItemMenuDelegate {
    private static let dataUsageMenuItemUnpairedTitle = NSLocalizedString(
        "Show data usage",
        comment: "statusitem menu item, shown instead of data usage of session when not paired")
    private static let dataUsageMenuItemPairedTitle = NSLocalizedString(
        "Data used: %@",
        comment: "statusitem menu item, shows amount of data used when paired")
    private static let sessionDurationMenuItemTitle = NSLocalizedString(
        "Online since %@",
        comment: "shown in status item menu when paired, showing the length of the session, like '5 min 2 sec'")
    private static let pairMenuItemUnpairedTitle = NSLocalizedString(
        "Not connected",
        comment: "shown in status item menu when not paired yet")
    private static let pairMenuItemPairedTitle = NSLocalizedString(
        "Connected to %@",
        comment: "shown in status item menu when paired")
    private static let preferencesMenuItemTitle = NSLocalizedString(
        "Preferences...",
        comment: "menu item in menubar for showing preferences window")
    private static let aboutMenuItemTitle = NSLocalizedString(
        "About Hotspot Menubar",
        comment: "menu item in menubar for showing about window")
    private static let quitMenuItemTitle = NSLocalizedString(
        "Quit",
        comment: "menu item for quitting the application")

    // `menu` is non-private because it needs to be accessed from StatusItem.swift
    var menu: NSMenu!
    
    private let sessionDurationFormatter = DateComponentsFormatter()

    private var dataUsageMenuItem: NSMenuItem!
    private var sessionDurationMenuItem: NSMenuItem!
    private var pairMenuItem: NSMenuItem!
    private var preferencesMenuItem: NSMenuItem!
    private var aboutMenuItem: NSMenuItem!
    private var quitMenuItem: NSMenuItem!

    private var preferencesWindowController: NSWindowController!
    private var dataUsageWindowController: NSWindowController!
    
    private var sessionChangeObserver: Any?

    private var pairingStatus: PairingStatus = .unpaired

    override init() {
        super.init()
        
        sessionDurationFormatter.unitsStyle = .short
        sessionDurationFormatter.allowedUnits = [.hour, .minute, .second]
        
        createMenu()
        observeSessionChanges()
    }

    private func createMenu() {
        menu = NSMenu(title: "")

        dataUsageMenuItem = NSMenuItem(
            title: StatusItemMenu.dataUsageMenuItemUnpairedTitle,
            action: #selector(showDataUsageWindow(sender:)),
            keyEquivalent: "")
        dataUsageMenuItem.target = self

        // Items with action=nil and no target are disabled, they exist only for informational purposes
        sessionDurationMenuItem = NSMenuItem(
            title: StatusItemMenu.sessionDurationMenuItemTitle,
            action: nil,
            keyEquivalent: "")
        // item is only visible when paired
        sessionDurationMenuItem.isHidden = true
        
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

        menu.insertItem(dataUsageMenuItem, at: 0)
        menu.insertItem(sessionDurationMenuItem, at: 1)
        menu.insertItem(pairMenuItem, at: 2)
        menu.insertItem(NSMenuItem.separator(), at: 3)
        menu.insertItem(preferencesMenuItem, at: 4)
        menu.insertItem(aboutMenuItem, at: 5)
        menu.insertItem(quitMenuItem, at: 6)
    }
    
    private func observeSessionChanges() {
        // We don't save the addObserver result because we want the observation to stay active during the lifetime of this app
        let _ = PersistentContainer.observeSessionChanges { [unowned self] session in
            DispatchQueue.main.async {
                guard let phoneName = pairingStatus.phoneName else { return }
                let sessionDuration = session.created!.distance(to: Date())
                let sessionDurationText = self.sessionDurationFormatter.string(from: sessionDuration)!
                let dataUsageText = Utils.byteCountFormatter.string(fromByteCount: session.bytesTransferred)
                                
                self.dataUsageMenuItem.title = String(format: StatusItemMenu.dataUsageMenuItemPairedTitle, dataUsageText)
                self.pairMenuItem.title = String(format: StatusItemMenu.pairMenuItemPairedTitle, phoneName)
                self.sessionDurationMenuItem.title = String(format: StatusItemMenu.sessionDurationMenuItemTitle, sessionDurationText)
            }
        }
    }

    @IBAction private func showDataUsageWindow(sender: Any) {
        if dataUsageWindowController == nil {
            let storyboard = NSStoryboard(name: "DataUsageWindow", bundle: nil)
            dataUsageWindowController = storyboard.instantiateInitialController() as? NSWindowController
        }
        dataUsageWindowController!.showWindow(sender)
    }

    @IBAction private func showPreferencesWindow(sender: Any) {
        if preferencesWindowController == nil {
            let storyboard = NSStoryboard(name: "PreferencesWindow", bundle: nil)
            preferencesWindowController = storyboard.instantiateInitialController() as? NSWindowController
        }
        preferencesWindowController!.showWindow(sender)
    }

    @IBAction private func showAboutWindow(sender: Any) {
        NSApp.orderFrontStandardAboutPanel(sender)
        NSApp.activate(ignoringOtherApps: true)
    }

    @IBAction private func quitApplication(sender: Any) {
        NSApp.terminate(sender)
    }

    // MARK: StatusItemMenuDelegate
    func pairingStatusUpdated(pairingStatus: PairingStatus) {
        self.pairingStatus = pairingStatus
        
        // UI needs to be updated in main loop
        DispatchQueue.main.async {
            if let phoneName = pairingStatus.phoneName {
                self.sessionDurationMenuItem.isHidden = false
                
                self.pairMenuItem.title = String(format: StatusItemMenu.pairMenuItemPairedTitle, phoneName)
                self.dataUsageMenuItem.title = String(format: StatusItemMenu.dataUsageMenuItemPairedTitle, 0)
                self.sessionDurationMenuItem.title = String(format: StatusItemMenu.sessionDurationMenuItemTitle,
                                                            self.sessionDurationFormatter.string(from: 0.0)!)
            } else {
                self.sessionDurationMenuItem.isHidden = true
                
                self.pairMenuItem.title = StatusItemMenu.pairMenuItemUnpairedTitle
                self.dataUsageMenuItem.title = StatusItemMenu.dataUsageMenuItemUnpairedTitle
            }
        }
    }
}
