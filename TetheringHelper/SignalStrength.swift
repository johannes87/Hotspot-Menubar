//
//  SignalStrengthImage.swift
//  TetheringHelper
//
//  Created by Johannes Bittner on 12.08.19.
//  Copyright © 2019 Johannes Bittner. All rights reserved.
//

import Cocoa

class SignalStrength {
    // TODO needs to be in class, not in function; why?
    let statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    
    var signalQuality = SignalQuality.no_signal
    var signalType = SignalType.two_g
    
    enum SignalQuality: Int {
        case no_signal = 0
        case one_bar = 1
        case two_bars = 2
        case three_bars = 3
        case four_bars = 4
    }
    
    enum SignalType {
        case two_g
        case edge
        case three_g
        case hsdpa
        case lte
    }
    
    public func setSignalStrength(signalQuality: SignalQuality, signalType: SignalType) {
        self.signalQuality = signalQuality
        self.signalType = signalType
        drawStatusItem()
    }
    
    private func drawStatusItem() {
        // https://stackoverflow.com/questions/12714923/os-x-icons-size
        let imageSize = NSSize.init(width: 18.0, height: 18.0)
        let signalBarLineWidth = 1
        let signalBarWidth: CGFloat = 3
        
        
        let statusItemImage = NSImage(size: imageSize, flipped: false, drawingHandler: {
            (dstRect: NSRect) -> Bool in
        
            // TODO: figure out why some lines are drawn fuzzy
            
            let path = NSBezierPath()
            path.lineWidth = CGFloat(signalBarLineWidth)
            NSColor.black.setStroke()
            
            let bar1Rect = NSRect(x: NSMinX(dstRect), y: NSMinY(dstRect), width: signalBarWidth, height: 3)
            path.appendRect(bar1Rect)
            path.stroke()
            if self.signalQuality.rawValue > 0 {
                path.fill()
            }
            
            let bar2Rect = NSRect(x: NSMinX(dstRect) + signalBarWidth+2, y: NSMinY(dstRect), width: signalBarWidth, height: 6)
            path.appendRect(bar2Rect)
            path.stroke()
            if self.signalQuality.rawValue > 1 {
                path.fill()
            }
            
            let bar3Rect = NSRect(x: NSMinX(dstRect) + signalBarWidth*2+4, y: NSMinY(dstRect), width: signalBarWidth, height: 10)
            path.appendRect(bar3Rect)
            path.stroke()
            if self.signalQuality.rawValue > 2 {
                path.fill()
            }
            
            let bar4Rect = NSRect(x: NSMinX(dstRect) + signalBarWidth*3+6, y: NSMinY(dstRect), width: signalBarWidth, height: 14)
            path.appendRect(bar4Rect)
            path.stroke()
            if self.signalQuality.rawValue > 3 {
                path.fill()
            }
            
            return true
        })
        
        statusBarItem.button?.image = statusItemImage
    }
}
