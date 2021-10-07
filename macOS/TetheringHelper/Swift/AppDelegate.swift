//
//  AppDelegate.swift
//  TetheringHelper
//
//  Created by Johannes Bittner on 03.08.19.
//  Copyright © 2019 Johannes Bittner. All rights reserved.
//

import Cocoa
import os

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    private let statusItem = StatusItem()
    private let sessionStorage = SessionStorage()

    private var androidConnector: AndroidConnector!
    private var sessionTracker: SessionTracker!

    private var firsttimeUserWindowController: NSWindowController?


    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // don't show dock icon or application menu
        NSApp.setActivationPolicy(.accessory)

        firsttimeUserDialog()

        androidConnector = AndroidConnector(
            statusItemDelegate: statusItem,
            statusItemMenuDelegate: statusItem.statusItemMenu
        )
        sessionTracker = SessionTracker(
            statusItemMenuDelegate: statusItem.statusItemMenu
        )
        startBackgroundThread()
    }

    private func firsttimeUserDialog() {
        // No sessions means the user hasn't connected to the phone yet
        if sessionStorage.getTetheringSessions().count != 0 {
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
                // TODO: diablo 2 play disc transfer: 615MB shown vs 582MB filesize; check how much data was uploaded on xfer
                self.sessionTracker.trackSession(
                    pairingStatus: self.androidConnector.pairingStatus,
                    localInterfaceName: self.androidConnector.tetheringInterfaceName
                )

                Thread.sleep(forTimeInterval: Double(PreferencesStorage.refreshStatusDelay))
            }
        }
    }
}
