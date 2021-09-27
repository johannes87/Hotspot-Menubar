//
//  StatusItemWindowController.swift
//  TetheringHelper
//
//  Created by Johannes Bittner on 27.06.21.
//  Copyright © 2021 Johannes Bittner. All rights reserved.
//

import Cocoa

/// StatusItemWindowController is used for windows created by StatusItem.swift
class StatusItemWindowController: NSWindowController {
    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        bringToFront()
        window?.center()
    }

    // TODO: make window close with cmd+w

    /// bringToFront is needed so that the created window isn't obscured by other windows
    private func bringToFront() {
        window?.makeKeyAndOrderFront(self)
        NSApp.activate(ignoringOtherApps: true)
    }
}
