//
//  StatusItemWindowController.swift
//  TetheringHelper
//
//  Created by Johannes Bittner on 27.06.21.
//  Copyright © 2021 Johannes Bittner. All rights reserved.
//

import Cocoa

/// FrontCenterWindowController is used to bring a window to front and center it
class FrontCenterWindowController: NSWindowController {
    override func windowDidLoad() {
        bringToFront()
        // make sure window position is not restored, so centering works
        window?.isRestorable = false
        window?.center()
    }
    
    override func showWindow(_ sender: Any?) {
        // ensure window is brought to front even if it's been loaded before
        bringToFront()
    }

    // TODO: make window close with cmd+w

    /// bringToFront is needed so that the created window isn't obscured by other windows
    private func bringToFront() {
        window?.makeKeyAndOrderFront(self)
        NSApp.activate(ignoringOtherApps: true)
    }
}
