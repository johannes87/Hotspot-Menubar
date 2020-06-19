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


    override func viewDidAppear() {
        super.viewDidAppear()
        let refreshStatusDelay = PreferencesStorage.getRefreshStatusDelay()
        updateRefreshStatusLabel(sliderValue: refreshStatusDelay)
        refreshStatusSlider.integerValue = refreshStatusDelay
    }

    @IBAction func autoStartCheckboxChanged(_ sender: NSButton) {
        // TODO: implement auto starting of app
        print("auto start checkbox", sender.integerValue != 0)
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
