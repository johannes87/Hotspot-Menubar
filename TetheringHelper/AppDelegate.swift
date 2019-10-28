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
    let signalStrength = SignalStrength()
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        signalStrength.setSignalStrength(
            signalQuality: SignalStrength.SignalQuality.three_bars,
            signalType: SignalStrength.SignalType.three_g)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

