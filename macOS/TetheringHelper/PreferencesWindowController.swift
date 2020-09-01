//
//  PreferencesWindowController.swift
//  TetheringHelper
//
//  Created by Johannes Bittner on 10.05.20.
//  Copyright © 2020 Johannes Bittner. All rights reserved.
//

import Cocoa

class PreferencesWindowController: NSWindowController, NSWindowDelegate {
    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        bringToFront()
    }

    private func bringToFront() {
        window?.makeKeyAndOrderFront(self)
        NSApp.activate(ignoringOtherApps: true)
    }
}
