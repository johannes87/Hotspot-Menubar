//
//  SignalStatusItem.swift
//  TetheringHelper
//
//  Created by Johannes Bittner on 12.08.19.
//  Copyright © 2019 Johannes Bittner. All rights reserved.
//

import Cocoa

class SignalStatusItem {
    private let statusItem: NSStatusItem = NSStatusBar.system.statusItem(
        withLength: NSStatusItem.squareLength)
    private let statusItemMenu = SignalStatusItemMenu()

    private var signalQuality = SignalQuality.no_signal
    private var signalType = SignalType.no_signal

    init() {
        statusItem.menu = statusItemMenu.menu
        self.drawStatusItem()
    }

    public func setSignal(signalQuality: SignalQuality, signalType: SignalType) {
        self.signalQuality = signalQuality
        self.signalType = signalType

        self.drawStatusItem()
    }

    private func drawStatusItem() {
        // explicitly draw UI in main thread, necessary if called from another thread
        DispatchQueue.main.async {
            // https://stackoverflow.com/questions/12714923/os-x-icons-size
            let imageSize = NSSize.init(width: 18.0, height: 18.0)

            let statusItemImage = NSImage(
                size: imageSize,
                flipped: false,
                drawingHandler: { (dstRect: NSRect) -> Bool in
                    self.drawSignalBars(dstRect)
                    self.drawSignalType(dstRect)
                    return true
            })

            self.statusItem.button?.image = statusItemImage
        }
    }

    // Used in drawStatusItem to draw the bar shapes for the signalQuality
    private func drawSignalBars(_ dstRect: NSRect) {
        // TODO: figure out why some lines are drawn fuzzy
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

    // Used in drawStatusItem to draw the text for the signalType (2G, 3G, ...)
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
}