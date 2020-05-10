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
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        window?.orderOut(sender)
        return false
    }
}
