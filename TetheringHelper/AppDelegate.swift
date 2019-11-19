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

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        cellularSignal.setSignal(
            signalQuality: CellularSignal.SignalQuality.no_signal,
            signalType: CellularSignal.SignalType.no_signal)

    }

    func applicationWillTerminate(_ aNotification: Notification) {
    }


}

