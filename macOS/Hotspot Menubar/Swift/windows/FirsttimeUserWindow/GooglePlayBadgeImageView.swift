//
//  GooglePlayBadgeImageView.swift
//  Hotspot Menubar
//
//  Created by Johannes Bittner on 07.10.21.
//

import Cocoa

class GooglePlayBadgeButton: NSButton {

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .pointingHand)
    }
}
