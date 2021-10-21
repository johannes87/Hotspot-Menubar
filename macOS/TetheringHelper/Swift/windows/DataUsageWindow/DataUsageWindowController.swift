//
//  DataUsageWindowController.swift
//  TetheringHelper
//
//  Created by Johannes Bittner on 20.10.21.
//

import Cocoa

class DataUsageWindowController: FrontCenterWindowController {
    
    private var noSessionsViewController: NSViewController!
    private var hasSessionsViewController: NSViewController!

    override func windowDidLoad() {
        super.windowDidLoad()
        noSessionsViewController = NSStoryboard(name: "DataUsageWindow", bundle: nil)
            .instantiateController(withIdentifier: "noSessions") as? NSViewController
        hasSessionsViewController = NSStoryboard(name: "DataUsageWindow", bundle: nil)
            .instantiateController(withIdentifier: "hasSessions") as? DataUsageViewController
    }
    
    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        
        if PersistentContainer.shared.getTetheringSessions().count == 0 {
            contentViewController = noSessionsViewController
        } else {
            contentViewController = hasSessionsViewController
        }
    }
}
