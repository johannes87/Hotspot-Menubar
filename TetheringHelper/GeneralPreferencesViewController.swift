//
//  PreferencesViewController.swift
//  TetheringHelper
//
//  Created by Johannes Bittner on 10.05.20.
//  Copyright © 2020 Johannes Bittner. All rights reserved.
//

import Cocoa

class GeneralPreferencesViewController: NSViewController {
    @IBOutlet weak var refreshStateLabel: NSTextField!
    @IBOutlet weak var refreshStateSlider: NSSlider!


    override func viewDidAppear() {
        super.viewDidAppear()
        updateRefreshStateLabel()
    }

    @IBAction func refreshStateSliderChanged(_ sender: NSSlider) {
        updateRefreshStateLabel()
    }

    private func updateRefreshStateLabel() {
        refreshStateLabel.stringValue = String(
            format: NSLocalizedString("PreferencesRefreshStatusLabel",
                comment: "The label for the refresh status slider in the preferences pane"),
            refreshStateSlider.integerValue)
    }
}
