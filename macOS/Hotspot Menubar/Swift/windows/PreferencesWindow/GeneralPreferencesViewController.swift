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
    @IBOutlet weak var refreshStatusLabel: NSTextField!
    @IBOutlet weak var refreshStatusSlider: NSSlider!
    @IBOutlet weak var runOnStartupCheckbox: NSButton!


    override func viewDidAppear() {
        super.viewDidAppear()
        let refreshStatusDelay = PreferencesStorage.refreshStatusDelay
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
        PreferencesStorage.refreshStatusDelay = sender.integerValue
    }

    private func updateRefreshStatusLabel(sliderValue: Int) {
        // TODO: make it like Activity Monitor: Very often / Often / Normal
        // name it "Status update frequency"
        refreshStatusLabel.stringValue = String(
            format: NSLocalizedString("PreferencesRefreshStatusLabel",
                comment: "The label for the refresh status slider in the preferences pane"),
            sliderValue)
    }
}
