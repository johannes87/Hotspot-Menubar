//
//  AppDelegate.swift
//  Hotspot Menubar
//
//  Created by Johannes Bittner on 03.08.19.
//  Copyright © 2019 Johannes Bittner. All rights reserved.
//

import Cocoa
import os

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    private let statusItem = StatusItem()

    private var androidConnector: AndroidConnector!
    private var sessionTracker: SessionTracker!
    private var transferNotification: TransferNotification!

    private var firsttimeUserWindowController: NSWindowController?


    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // don't show dock icon or application menu
        NSApp.setActivationPolicy(.accessory)

        PreferencesStorage.registerDefaults()
        firsttimeUserDialog()

        androidConnector = AndroidConnector(
            statusItemDelegate: statusItem,
            statusItemMenuDelegate: statusItem.statusItemMenu
        )
        sessionTracker = SessionTracker(
            statusItemMenuDelegate: statusItem.statusItemMenu
        )
        transferNotification = TransferNotification()

        startBackgroundThread()
    }

    private func firsttimeUserDialog() {
        // No sessions means the user hasn't connected to the phone yet
        if PersistentContainer.shared.getTetheringSessions().count != 0 {
            return
        }

        if firsttimeUserWindowController == nil {
            let storyboard = NSStoryboard(name: "FirsttimeUserWindow", bundle: nil)
            firsttimeUserWindowController = storyboard.instantiateInitialController() as? NSWindowController
        }
        firsttimeUserWindowController!.showWindow(nil)
    }

    private func startBackgroundThread() {
        DispatchQueue.global(qos: .background).async {
            while true {
                os_log(.debug, "Running background thread")

                // TODO: why does getSignal take so long?
                self.androidConnector.getSignal()

                self.sessionTracker.trackSession(
                    pairingStatus: self.androidConnector.pairingStatus,
                    localInterfaceName: self.androidConnector.tetheringInterfaceName
                )

                self.transferNotification.maybeShowNotification(
                    sessionActive: self.sessionTracker.sessionActive,
                    bytesTransferred: self.sessionTracker.bytesTransferred
                )

                Thread.sleep(forTimeInterval: Constants.refreshStatusDelay)
            }
        }
    }
}
