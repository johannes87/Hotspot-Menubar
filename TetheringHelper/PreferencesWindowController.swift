//
//  PreferencesWindowController.swift
//  TetheringHelper
//
//  Created by Johannes Bittner on 10.05.20.
//  Copyright © 2020 Johannes Bittner. All rights reserved.
//

import Cocoa

class PreferencesWindowController: NSWindowController, NSWindowDelegate {
    override func windowDidLoad() {
        super.windowDidLoad()
        bringToFront()
    }

    private func bringToFront() {
        NSApp.activate(ignoringOtherApps: true)
    }
}
