//
//  PreferencesViewController.swift
//  Hotspot Menubar
//
//  Created by Johannes Bittner on 10.05.20.
//  Copyright © 2020 Johannes Bittner. All rights reserved.
//

import Cocoa

class GeneralPreferencesViewController: NSViewController {
    // TODO: make UI elements selectable by TAB
    @IBOutlet weak var runOnStartupCheckbox: NSButton!

    override func viewDidAppear() {
        super.viewDidAppear()
        runOnStartupCheckbox.state = Autostart.isEnabled() ? .on : .off
    }

    @IBAction func runOnStartupCheckboxChanged(_ sender: NSButton) {
        let runOnStartup = sender.integerValue != 0
        Autostart.setAutostart(enabled: runOnStartup)
    }
}
