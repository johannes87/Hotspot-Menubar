//
//  DataUsageVisualization.swift
//  TetheringHelper
//
//  Created by Johannes Bittner on 29.06.21.
//  Copyright © 2021 Johannes Bittner. All rights reserved.
//

import Cocoa
import CoreGraphics


@IBDesignable
class DataUsageVisualization : NSView {
    var dataUsage: [Int64] = [Int64](repeating: 50, count: 31) {
        didSet {
            needsDisplay = true
        }
    }

    // try this: https://developer.apple.com/documentation/appkit/nstrackingarea
    override func draw(_ dirtyRect: NSRect) {
        let daysInMonth = dataUsage.count
        let maxUsageInMonth = dataUsage.max()

        // Graphical appearance
        let barWidth = 15
        let barMarginX = 5
        let labelHeight = 15
        let marginYBetweenBarAndLabel = 5
        let marginYBetweenBarAndTopEdge = 10

        // Center the chart horizontally
        let chartWidth = (barWidth + barMarginX) * daysInMonth - barMarginX
        let chartStartX = (Int(bounds.width) - chartWidth) / 2

        // Draw the chart
        let barChartPath = NSBezierPath()
        for day in 1...daysInMonth {
            let dayXPos = (day - 1) * (barWidth + barMarginX) + chartStartX
            let maxBarHeight = Int(bounds.height) - labelHeight - marginYBetweenBarAndLabel - marginYBetweenBarAndTopEdge

            let barHeight = maxUsageInMonth != 0
                ? Int((Double(dataUsage[day - 1]) / Double(maxUsageInMonth!)) * Double(maxBarHeight))
                : 0

            // Draw the bar showing the data usage for a day
            let barRect = NSRect(
                x: dayXPos,
                y: labelHeight + marginYBetweenBarAndLabel,
                width: barWidth,
                height: barHeight
            )
            barChartPath.appendRoundedRect(barRect, xRadius: 5.0, yRadius: 5.0)

            // Draw the label for a day
            let dayLabel = String(day) as NSString
            let labelRect = NSRect(x: dayXPos, y: 0, width: barWidth, height: labelHeight)
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            let textAttributes = [
                NSAttributedString.Key.foregroundColor: NSColor.labelColor,
                NSAttributedString.Key.paragraphStyle: paragraphStyle
            ]
            dayLabel.draw(in: labelRect, withAttributes: textAttributes)
        }
        NSColor.blue.setFill()
        barChartPath.fill()

        // Draw rounded outline around NSView for better separation
        let outlinePath = NSBezierPath()
        outlinePath.appendRoundedRect(bounds, xRadius: 5.0, yRadius: 5.0)
        NSColor.labelColor.setStroke()
        outlinePath.stroke()
    }
}
