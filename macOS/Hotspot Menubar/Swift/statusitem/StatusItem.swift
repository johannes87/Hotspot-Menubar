//
//  StatusItem.swift
//  Hotspot Menubar
//
//  Created by Johannes Bittner on 12.08.19.
//  Copyright © 2019 Johannes Bittner. All rights reserved.
//

import Cocoa

class StatusItem: StatusItemDelegate {
    private static let statusItemLengthUnpaired = 18.0

    private(set) var statusItemMenu: StatusItemMenu!

    private let cocoaStatusItem: NSStatusItem
    private var statusItemLength: CGFloat {
        get {
            if pairingStatus.isPaired {
                // the final length depends on the width of the signal type string
                let signalType = getAttributedStringForSignalType()
                return StatusItem.statusItemLengthUnpaired + signalType.size().width
            } else {
                return StatusItem.statusItemLengthUnpaired
            }
        }
    }

    private var signalQuality = SignalQuality.no_signal
    private var signalType = SignalType.no_signal
    private var pairingStatus = PairingStatus.unpaired


    init() {
        statusItemMenu = StatusItemMenu()
        cocoaStatusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        cocoaStatusItem.menu = statusItemMenu.menu

        self.drawStatusItem()
    }

    private func drawStatusItem() {
        DispatchQueue.main.async {
            // choosing 18 height: https://stackoverflow.com/questions/12714923/os-x-icons-size
            let imageSize = NSSize.init(
                width: self.statusItemLength, height: 18.0
            )

            let statusItemImage = NSImage(
                size: imageSize,
                flipped: false) { (dstRect: NSRect) -> Bool in
                    self.drawSignalBars(dstRect)

                    if self.pairingStatus.isPaired {
                        self.drawSignalType(dstRect)
                    } else {
                        self.drawDisconnectedStrikeThrough(dstRect)
                    }
                    return true
            }

            self.cocoaStatusItem.button?.image = statusItemImage
        }
    }

    /// Used in drawStatusItem to draw the bar shapes for the signalQuality
    private func drawSignalBars(_ dstRect: NSRect) {
        let signalBarRectWidth: CGFloat = 3

        let xOffset = 0.0
        let yOffset = 3.0

        let signalBar1Rect = NSRect(
            x: NSMinX(dstRect) + xOffset,
            y: NSMinY(dstRect) + yOffset,
            width: signalBarRectWidth,
            height: 3
        )
        drawSignalBar(signalBarRect: signalBar1Rect, minActiveQuality: 1)

        let signalBar2Rect = NSRect(
            x: NSMinX(dstRect) + signalBarRectWidth + 1 + xOffset,
            y: NSMinY(dstRect) + yOffset,
            width: signalBarRectWidth,
            height: 6
        )
        drawSignalBar(signalBarRect: signalBar2Rect, minActiveQuality: 2)

        let signalBar3Rect = NSRect(
            x: NSMinX(dstRect) + signalBarRectWidth * 2 + 2 + xOffset,
            y: NSMinY(dstRect) + yOffset,
            width: signalBarRectWidth,
            height: 9
        )
        drawSignalBar(signalBarRect: signalBar3Rect, minActiveQuality: 3)

        let signalBar4Rect = NSRect(
            x: NSMinX(dstRect) + signalBarRectWidth * 3 + 3 + xOffset,
            y: NSMinY(dstRect) + yOffset,
            width: signalBarRectWidth,
            height: 12
        )
        drawSignalBar(signalBarRect: signalBar4Rect, minActiveQuality: 4)
    }

    private func drawSignalBar(signalBarRect rect: NSRect, minActiveQuality: Int) {
        let alphaBarInactive: CGFloat = 0.25
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
        let xOffset = 18.0
        let yOffset = -3.0

        let signalType = getAttributedStringForSignalType()
        signalType.draw(
            in: NSRect(
                x: dstRect.origin.x + xOffset,
                y: dstRect.origin.y + yOffset,
                width: dstRect.width,
                height: dstRect.height
            )
        )
    }

    /// - Returns: the NSAttributedString that is going to be drawn into the status item
    private func getAttributedStringForSignalType() -> NSAttributedString {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 10),
            .foregroundColor: NSColor.labelColor
        ]

        return NSAttributedString(
            string: signalType.rawValue,
            attributes: attributes
        )
    }

    /// This draws a line that "strikes through" the signal bars, to communicate there's no connection with the phone.
    private func drawDisconnectedStrikeThrough(_ dstRect: NSRect) {
        let xOffset = 2
        let yOffset = 3

        let path = NSBezierPath()
        // A line with slope = -1
        path.move(to: .init(x: 12 + xOffset, y: 0 + yOffset))
        path.line(to: .init(x: 0 + xOffset, y: 12 + yOffset))
        NSColor.labelColor.setStroke()
        path.stroke()
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
