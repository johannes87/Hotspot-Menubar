//
//  FirsttimeUserViewController.swift
//  TetheringHelper
//
//  Created by Johannes Bittner on 06.10.21.
//

import Foundation
import AppKit

// TODO: update this with link to app
private let playstoreLink = "https://play.google.com"

class FirsttimeUserViewController: NSViewController {
    @IBOutlet weak var qrCodeImageView: NSImageView!

    override func viewDidLoad() {
        qrCodeImageView.image = Utils.generateQRCode(from: playstoreLink)
    }


    @IBAction func googlePlayBadgeClicked(_ sender: Any) {
        if let url = URL(string: playstoreLink) {
            NSWorkspace.shared.open(url)
        }
    }

}
