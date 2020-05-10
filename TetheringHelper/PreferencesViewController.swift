//
//  PreferencesViewController.swift
//  TetheringHelper
//
//  Created by Johannes Bittner on 10.05.20.
//  Copyright © 2020 Johannes Bittner. All rights reserved.
//

import Cocoa

class PreferencesViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        preferredContentSize = NSMakeSize(view.frame.size.width, view.frame.size.height)
    }

    override func viewDidAppear() {
        super.viewDidAppear()
    }
}
