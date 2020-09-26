//
//  AppDelegate.swift
//  TetheringHelper
//
//  Created by Johannes Bittner on 03.08.19.
//  Copyright © 2019 Johannes Bittner. All rights reserved.
//

import Cocoa
import os

// TODO: implement dark mode
// TODO: put non-swift files like Assets.xcassets in xcode group
// TODO: check metered connection support => https://apple.stackexchange.com/questions/215454/managing-metered-connections-on-osx


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    private let statusItem = StatusItem()
    private var androidConnector: AndroidConnector!
    private var sessionTracker: SessionTracker!


    func applicationDidFinishLaunching(_ aNotification: Notification) {
        startBackgroundLoop()
        androidConnector = AndroidConnector(
            statusItemDelegate: statusItem,
            statusItemMenuDelegate: statusItem.statusItemMenu
        )
        sessionTracker = SessionTracker(
            statusItemMenuDelegate: statusItem.statusItemMenu
        )

    }

    private func startBackgroundLoop() {
        DispatchQueue.global(qos: .background).async {
            while true {
                os_log(.debug, "Running background loop")

                // TODO: why does getSignal take so long?
                self.androidConnector.getSignal()
                // TODO: diablo 2 play disc transfer: 615MB shown vs 582MB filesize; check how much data was uploaded on xfer
                self.sessionTracker.trackSession(
                    pairingStatus: self.androidConnector.pairingStatus,
                    localInterfaceName: self.androidConnector.localInterfaceName
                )

                Thread.sleep(forTimeInterval: Double(PreferencesStorage.refreshStatusDelay))
            }
        }
    }
}
