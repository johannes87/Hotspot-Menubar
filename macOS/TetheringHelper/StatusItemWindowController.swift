//
//  StatusItemWindowController.swift
//  TetheringHelper
//
//  Created by Johannes Bittner on 27.06.21.
//  Copyright © 2021 Johannes Bittner. All rights reserved.
//

import Cocoa

/// StatusItemWindowController is used for windows started from the status item
class StatusItemWindowController: NSWindowController {
    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        bringToFront()
        window?.center()
    }

    /// bringToFront is needed so that the created window isn't obscured by other windows
    private func bringToFront() {
        window?.makeKeyAndOrderFront(self)
        NSApp.activate(ignoringOtherApps: true)
    }
}
