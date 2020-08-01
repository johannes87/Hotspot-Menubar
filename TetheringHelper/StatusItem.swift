//
//  StatusItem.swift
//  TetheringHelper
//
//  Created by Johannes Bittner on 12.08.19.
//  Copyright © 2019 Johannes Bittner. All rights reserved.
//

import Cocoa

class StatusItem {
    private let cocoaStatusItem: NSStatusItem
    private let statusItemMenu = StatusItemMenu()

    private var signalQuality = SignalQuality.no_signal
    private var signalType = SignalType.no_signal
    private var pairingStatus = PairingStatus.unpaired


    init() {
        cocoaStatusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        cocoaStatusItem.menu = statusItemMenu.menu

        self.drawStatusItem()
    }

    func setSignal(signalQuality: SignalQuality, signalType: SignalType) {
        self.signalQuality = signalQuality
        self.signalType = signalType
        self.drawStatusItem()
    }

    func setPairingStatus(_ pairingStatus: PairingStatus) {
        self.pairingStatus = pairingStatus
        self.statusItemMenu.setPairingStatus(pairingStatus: pairingStatus)
        self.drawStatusItem()
    }

    private func drawStatusItem() {
        DispatchQueue.main.async {
            // choosing 18/18: https://stackoverflow.com/questions/12714923/os-x-icons-size
            let imageSize = NSSize.init(width: 18.0, height: 18.0)

            let statusItemImage = NSImage(
                size: imageSize,
                flipped: false) { (dstRect: NSRect) -> Bool in
                    self.drawSignalBars(dstRect)

                    if self.pairingStatus.isPaired {
                        self.drawSignalType(dstRect)
                    } else {
                        self.drawUnpairedIcon(dstRect)
                    }
                    return true
            }

            self.cocoaStatusItem.button?.image = statusItemImage
        }
    }

    /// Used in drawStatusItem to draw the bar shapes for the signalQuality
    private func drawSignalBars(_ dstRect: NSRect) {
        // TODO: figure out why some lines are drawn fuzzy
        // https://stackoverflow.com/questions/58904168/how-do-i-draw-a-rectangle-with-equal-line-widths-into-an-nsstatusitembutton
        let signalBarLineWidth = 1
        let signalBarRectWidth: CGFloat = 3

        let path = NSBezierPath()
        path.lineWidth = CGFloat(signalBarLineWidth)
        NSColor.black.setStroke()

        let signalBar1Rect = NSRect(x: NSMinX(dstRect), y: NSMinY(dstRect), width: signalBarRectWidth, height: 3)
        path.appendRect(signalBar1Rect)
        if self.signalQuality.rawValue == 1 {
            path.fill()
        }

        let signalBar2Rect = NSRect(x: NSMinX(dstRect) + signalBarRectWidth+2, y: NSMinY(dstRect), width: signalBarRectWidth, height: 6)
        path.appendRect(signalBar2Rect)
        if self.signalQuality.rawValue == 2 {
            path.fill()
        }

        let signalBar3Rect = NSRect(x: NSMinX(dstRect) + signalBarRectWidth*2+4, y: NSMinY(dstRect), width: signalBarRectWidth, height: 10)
        path.appendRect(signalBar3Rect)
        if self.signalQuality.rawValue == 3 {
            path.fill()
        }

        let signalBar4Rect = NSRect(x: NSMinX(dstRect) + signalBarRectWidth*3+6, y: NSMinY(dstRect), width: signalBarRectWidth, height: 14)
        path.appendRect(signalBar4Rect)
        if self.signalQuality.rawValue == 4 {
            path.fill()
        }

        // stroke all the appended rects
        path.stroke()
    }

    /// Used in drawStatusItem to draw the text for the signalType (2G, 3G, ...)
    private func drawSignalType(_ dstRect: NSRect) {
        let fontSmall = NSFont.systemFont(ofSize: 6)
        let fontBig = NSFont.systemFont(ofSize: 7)

        var font: NSFont
        if self.signalType == SignalType.lte {
            // the string "LTE" requires more space
            font = fontSmall
        } else {
            font = fontBig
        }

        let textFontAttributes = [
            NSAttributedString.Key.font: font,
            NSAttributedString.Key.foregroundColor: NSColor.black,
        ]

        let signalTypeStr = NSString(string: self.signalType.rawValue)
        signalTypeStr.draw(in: dstRect, withAttributes: textFontAttributes)
    }

    /// Draw an "unpaired" icon in the top-left corner when this app is not paired with an Android device
    private func drawUnpairedIcon(_ dstRect: NSRect) {
        // TODO: fulfill icon license http://www.iconarchive.com/show/windows-8-icons-by-icons8/Network-Disconnected-icon.html
        // TODO: draw icon again as vector image, by backdropping the bitmap and drawing on top
        let unpairedIcon = NSImage(named: "unpairedIcon")!
        guard dstRect.width == 18 && dstRect.height == 18 else { return }

        // the destination is assumed to be 18x18 px here
        unpairedIcon.draw(in: NSRect(x: 0, y: 8, width: 10, height: 10))
    }
}
