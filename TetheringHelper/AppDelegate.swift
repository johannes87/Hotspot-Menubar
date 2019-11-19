//
//  AppDelegate.swift
//  TetheringHelper
//
//  Created by Johannes Bittner on 03.08.19.
//  Copyright © 2019 Johannes Bittner. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    let cellularSignal = CellularSignal()
    let androidConnector = AndroidConnector()

    private func startNetworkLoop() {
        let networkQueue = DispatchQueue(label: "network-queue")
        networkQueue.async {
            while true {
                print("timestamp \(NSDate().timeIntervalSince1970)")

                self.androidConnector.fetchSignal()

                self.cellularSignal.setSignal(
                    signalQuality: self.androidConnector.signalQuality,
                    signalType: self.androidConnector.signalType)

                // TODO: put time interval into preferences
                Thread.sleep(forTimeInterval: 1)
            }
        }
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        startNetworkLoop()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
    }
}
