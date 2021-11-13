//
//  AppDelegate.swift
//  TetheringHelperAutostart
//
//  Created by Johannes Bittner on 25.06.20.
//  Copyright © 2020 Johannes Bittner. All rights reserved.
//

import Cocoa
import os

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    /// This helper app is needed to autostart TetheringHelper. It will always be running if autostart is enabled in preferences
    /// Derived from this article: https://medium.com/@hoishing/adding-login-items-for-macos-7d76458f6495
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        if !mainAppIsRunning() {
            runMainApp()
        }
    }

    private func mainAppIsRunning() -> Bool {
        let mainBundleName = "com.gmail.bittner.johannes.Hotspot-Menubar"
        let isRunning = NSWorkspace.shared.runningApplications.contains {
            $0.bundleIdentifier == mainBundleName
        }
        return isRunning
    }

    private func runMainApp() {
        var path = Bundle.main.bundlePath as NSString
        // Need to delete the last 4 components of the bundlePath to find path of main app, b/c this app
        // will be copied to Contents/Library/LoginItems during build of main app
        for _ in 1...4 {
            path = path.deletingLastPathComponent as NSString
        }
        NSWorkspace.shared.launchApplication(path as String)
    }
}
