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
    var dataStorage: DataStorage!
    var androidConnector: AndroidConnector!
    var statusItem: StatusItem!


    func applicationDidFinishLaunching(_ aNotification: Notification) {
        dataStorage = DataStorage()
        androidConnector = AndroidConnector()
        statusItem = StatusItem()

        startNetworkLoop()
    }

    private func startNetworkLoop() {
        DispatchQueue.global(qos: .background).async {
            while true {
                os_log(.debug, "Running network loop")

                self.androidConnector.getSignal()

                self.statusItem.setPairingStatus(
                    pairingStatus: self.androidConnector.pairingStatus)
                self.statusItem.setSignal(
                    signalQuality: self.androidConnector.signalQuality,
                    signalType: self.androidConnector.signalType)

                // TODO: put time interval into preferences
                Thread.sleep(forTimeInterval: 3)
            }
        }
    }
}
