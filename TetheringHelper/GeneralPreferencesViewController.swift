//
//  PreferencesViewController.swift
//  TetheringHelper
//
//  Created by Johannes Bittner on 10.05.20.
//  Copyright © 2020 Johannes Bittner. All rights reserved.
//

import Cocoa

class GeneralPreferencesViewController: NSViewController {
    @IBOutlet weak var refreshStatusLabel: NSTextField!
    @IBOutlet weak var refreshStatusSlider: NSSlider!
    @IBOutlet weak var runOnStartupCheckbox: NSButton!


    override func viewDidAppear() {
        super.viewDidAppear()
        let refreshStatusDelay = PreferencesStorage.getRefreshStatusDelay()
        updateRefreshStatusLabel(sliderValue: refreshStatusDelay)
        refreshStatusSlider.integerValue = refreshStatusDelay
        runOnStartupCheckbox.state = Autostart.isEnabled() ? .on : .off
    }

    @IBAction func runOnStartupCheckboxChanged(_ sender: NSButton) {
        let runOnStartup = sender.integerValue != 0
        Autostart.setAutostart(enabled: runOnStartup)
    }

    @IBAction func refreshStatusSliderChanged(_ sender: NSSlider) {
        updateRefreshStatusLabel(sliderValue: sender.integerValue)
        PreferencesStorage.setRefreshStatusDelay(newValue: sender.integerValue)
    }

    private func updateRefreshStatusLabel(sliderValue: Int) {
        refreshStatusLabel.stringValue = String(
            format: NSLocalizedString("PreferencesRefreshStatusLabel",
                comment: "The label for the refresh status slider in the preferences pane"),
            sliderValue)
    }
}
