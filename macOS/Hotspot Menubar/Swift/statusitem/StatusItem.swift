//
//  StatusItem.swift
//  Hotspot Menubar
//
//  Created by Johannes Bittner on 12.08.19.
//  Copyright © 2019 Johannes Bittner. All rights reserved.
//

import Cocoa

class StatusItem: StatusItemDelegate {
    private(set) var statusItemMenu: StatusItemMenu!

    private let cocoaStatusItem: NSStatusItem

    private var signalQuality = SignalQuality.no_signal
    private var signalType = SignalType.no_signal
    private var pairingStatus = PairingStatus.unpaired


    init() {
        statusItemMenu = StatusItemMenu()
        cocoaStatusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        cocoaStatusItem.menu = statusItemMenu.menu

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
        let signalBarRectWidth: CGFloat = 3

        let signalBar1Rect = NSRect(
            x: NSMinX(dstRect),
            y: NSMinY(dstRect),
            width: signalBarRectWidth,
            height: 3
        )
        drawSignalBar(signalBarRect: signalBar1Rect, minActiveQuality: 1)

        let signalBar2Rect = NSRect(
            x: NSMinX(dstRect) + signalBarRectWidth + 2,
            y: NSMinY(dstRect),
            width: signalBarRectWidth,
            height: 6
        )
        drawSignalBar(signalBarRect: signalBar2Rect, minActiveQuality: 2)

        let signalBar3Rect = NSRect(
            x: NSMinX(dstRect) + signalBarRectWidth * 2 + 4,
            y: NSMinY(dstRect),
            width: signalBarRectWidth,
            height: 10
        )
        drawSignalBar(signalBarRect: signalBar3Rect, minActiveQuality: 3)

        let signalBar4Rect = NSRect(
            x: NSMinX(dstRect) + signalBarRectWidth * 3 + 6,
            y: NSMinY(dstRect),
            width: signalBarRectWidth,
            height: 14
        )
        drawSignalBar(signalBarRect: signalBar4Rect, minActiveQuality: 4)
    }

    private func drawSignalBar(signalBarRect rect: NSRect, minActiveQuality: Int) {
        let alphaBarInactive: CGFloat = 0.2
        let alphaBarActive: CGFloat = 1

        if self.signalQuality.rawValue >= minActiveQuality {
            NSColor.labelColor.withAlphaComponent(alphaBarActive).setFill()
        } else {
            NSColor.labelColor.withAlphaComponent(alphaBarInactive).setFill()
        }

        let path = NSBezierPath()
        path.appendRoundedRect(rect, xRadius: 2, yRadius: 2)
        path.fill()
    }

    /// Used in drawStatusItem to draw the text for the signalType (2G, 3G, ...)
    private func drawSignalType(_ dstRect: NSRect) {
        let fontSmall = NSFont.systemFont(ofSize: 6)
        let fontBig = NSFont.systemFont(ofSize: 7)

        var font: NSFont
        if self.signalType == .lte || self.signalType == .five_g_plus {
            // some signal types require more space
            font = fontSmall
        } else {
            font = fontBig
        }

        let signalTypeStr = NSString(string: self.signalType.rawValue)
        signalTypeStr.draw(
            in: dstRect,
            withAttributes: [.font: font, .foregroundColor: NSColor.labelColor]
        )
    }

    /// Draw an "unpaired" icon in the top-left corner when this app is not paired with an Android device
    private func drawUnpairedIcon(_ dstRect: NSRect) {
        // TODO: fulfill icon license http://www.iconarchive.com/show/windows-8-icons-by-icons8/Network-Disconnected-icon.html
        // TODO: draw icon again as vector image, by backdropping the bitmap and drawing on top
        let unpairedIcon = NSImage(named: "unpairedIcon")!
        guard dstRect.width == 18 && dstRect.height == 18 else { return }

        let opacity = 0.3

        // the destination is assumed to be 18x18 px here
        unpairedIcon.draw(
            in: NSRect(x: 0, y: 8, width: 10, height: 10),
            from: .zero,
            operation: .sourceOver,
            fraction: opacity)
    }

    // MARK: StatusItemDelegate
    func signalUpdated(phoneSignal: PhoneSignal?) {
        if phoneSignal == nil {
            self.signalQuality = .no_signal
            self.signalType = .no_signal
        } else {
            self.signalQuality = phoneSignal!.quality
            self.signalType = phoneSignal!.type
        }
        drawStatusItem()
    }

    func pairingStatusUpdated(pairingStatus: PairingStatus) {
        self.pairingStatus = pairingStatus
        drawStatusItem()
    }

}
