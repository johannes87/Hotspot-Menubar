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
    
    private var sessionChangeObserver: Any?

    override func windowDidLoad() {
        super.windowDidLoad()
        noSessionsViewController = NSStoryboard(name: "DataUsageWindow", bundle: nil)
            .instantiateController(withIdentifier: "noSessions") as? NSViewController
        hasSessionsViewController = NSStoryboard(name: "DataUsageWindow", bundle: nil)
            .instantiateController(withIdentifier: "hasSessions") as? DataUsageViewController
        
        // make window automatically replace its "noSession" view controller when a session gets created
        if PersistentContainer.shared.getTetheringSessions().count == 0 {
            sessionChangeObserver = PersistentContainer.observeSessionChanges { [unowned self] _ in
                self.contentViewController = self.hasSessionsViewController
                self.window?.center()
                NotificationCenter.default.removeObserver(self.sessionChangeObserver!)
            }
        }
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
