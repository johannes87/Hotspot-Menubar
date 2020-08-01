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

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    let dataStorage = DataStorage()
    let androidConnector = AndroidConnector()
    let statusItem = StatusItem()


    func applicationDidFinishLaunching(_ aNotification: Notification) {
        startBackgroundLoop()
    }

    private func startBackgroundLoop() {
        DispatchQueue.global(qos: .background).async {
            while true {
                os_log(.debug, "Running background loop")

                self.androidConnector.getSignal()

                self.statusItem.setPairingStatus(self.androidConnector.pairingStatus)
                self.statusItem.setSignal(
                    signalQuality: self.androidConnector.signalQuality,
                    signalType: self.androidConnector.signalType)

                Thread.sleep(forTimeInterval: Double(PreferencesStorage.refreshStatusDelay))
            }
        }
    }
}
