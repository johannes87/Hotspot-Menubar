//
//  AppDelegate.swift
//  TetheringHelper
//
//  Created by Johannes Bittner on 03.08.19.
//  Copyright © 2019 Johannes Bittner. All rights reserved.
//

import Cocoa

// TODO: implement dark mode

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    let androidConnector = AndroidConnector()
    let dataStorage = DataStorage()
    var signalStatusItem: SignalStatusItem!

    private func startNetworkThread() {
        let networkQueue = DispatchQueue(label: "network", qos: .background)
        networkQueue.async {
            while true {
                print("network loop: time=\(NSDate().timeIntervalSince1970)")

                self.androidConnector.getSignal()

                self.signalStatusItem.setSignal(
                    signalQuality: self.androidConnector.signalQuality,
                    signalType: self.androidConnector.signalType)

                // TODO: put time interval into preferences
                Thread.sleep(forTimeInterval: 4)
            }
        }
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        signalStatusItem = SignalStatusItem(androidConnector)
        startNetworkThread()
    }

}
