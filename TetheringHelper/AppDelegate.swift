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

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        cellularSignal.setSignal(
            signalQuality: SignalQuality.no_signal,
            signalType: SignalType.no_signal)


        let networkQueue = DispatchQueue(label: "network-queue")
        networkQueue.async {
            while true {
                print("timestamp \(NSDate().timeIntervalSince1970)")

                self.cellularSignal.setSignal(
                    signalQuality: SignalQuality.allCases.randomElement()!,
                    signalType: SignalType.allCases.randomElement()!)

                // TODO: put time interval into preferences
                Thread.sleep(forTimeInterval: 1)
            }
        }

    }

    func applicationWillTerminate(_ aNotification: Notification) {
    }


}

