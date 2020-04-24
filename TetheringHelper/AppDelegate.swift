//
//  AppDelegate.swift
//  TetheringHelper
//
//  Created by Johannes Bittner on 03.08.19.
//  Copyright © 2019 Johannes Bittner. All rights reserved.
//

import Cocoa
import UserNotifications

// TODO: rename to TetheringStatus
// TODO: implement dark mode

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    let dataStorage = DataStorage()
    let androidConnector = AndroidConnector()

    var statusItem: StatusItem!


    func applicationDidFinishLaunching(_ aNotification: Notification) {
        statusItem = StatusItem(androidConnector: androidConnector)
        androidConnector.setStatusItem(statusItem)

        startNetworkThread()
    }

    private func startNetworkThread() {
        // TODO: check if we can use global .background queue instead, to avoid creating unnecessary queues
        let networkQueue = DispatchQueue(label: "network", qos: .background)
        networkQueue.async {
            while true {
                print("network loop: time=\(NSDate().timeIntervalSince1970)")

                self.androidConnector.getSignal()

                self.statusItem.setSignal(
                    signalQuality: self.androidConnector.signalQuality,
                    signalType: self.androidConnector.signalType)

                // TODO: put time interval into preferences
                Thread.sleep(forTimeInterval: 10)
            }
        }
    }
}
