//
//  DataUsageVisualization.swift
//  TetheringHelper
//
//  Created by Johannes Bittner on 29.06.21.
//  Copyright © 2021 Johannes Bittner. All rights reserved.
//

import Cocoa
import CoreGraphics

private let trackingAreaKeyBytesTransferred = "bytesTransferred"

@IBDesignable
class DataUsageVisualization : NSView {
    var dataUsage: [Int64] = [Int64](repeating: 50, count: 31) {
        didSet {
            needsDisplay = true
        }
    }

    private var dailyDataUsagePopover: NSPopover?

    override func draw(_ dirtyRect: NSRect) {
        let daysInMonth = dataUsage.count
        let maxUsageInMonth = dataUsage.max()

        // Ensure old tracking areas from previous draw are removed
        trackingAreas.forEach { trackingArea in
            removeTrackingArea(trackingArea)
        }

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
            let dayDataUsage = dataUsage[day - 1]

            let barHeight = maxUsageInMonth != 0
                ? Int((Double(dayDataUsage) / Double(maxUsageInMonth!)) * Double(maxBarHeight))
                : 0

            // Draw the bar showing the data usage for a day
            let barRect = NSRect(
                x: dayXPos,
                y: labelHeight + marginYBetweenBarAndLabel,
                width: barWidth,
                height: barHeight
            )
            barChartPath.appendRoundedRect(barRect, xRadius: 5.0, yRadius: 5.0)

            addTrackingArea(
                NSTrackingArea(
                    rect: barRect,
                    options: [.activeAlways, .mouseEnteredAndExited],
                    owner: self,
                    userInfo: [trackingAreaKeyBytesTransferred: dayDataUsage])
            )


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

    override func mouseEntered(with event: NSEvent) {
        let bytesTransferred = event.trackingArea?.userInfo?[trackingAreaKeyBytesTransferred]! as! Int64
        let megaBytesTransferredText = String(format: "%.2f MB", Double(bytesTransferred) / 1024 / 1024)

        let contentViewController = NSViewController()
        contentViewController.view = NSView()

        let textField = NSTextField(labelWithAttributedString: NSAttributedString(
            string: megaBytesTransferredText,
            attributes: [.font: NSFont.boldSystemFont(ofSize: 12)]
        ))

        // Center textField in contentViewController
        contentViewController.view.frame = NSRect(
            x: 0,
            y: 0,
            width: textField.frame.width + 10,
            height: textField.frame.height + 10
        )
        textField.frame = NSRect(
            x: (contentViewController.view.frame.width - textField.frame.width) / 2,
            y: (contentViewController.view.frame.height - textField.frame.height) / 2,
            width: textField.frame.width,
            height: textField.frame.height
        )
        contentViewController.view.addSubview(textField)

        textField.allowsEditingTextAttributes = true

        if dailyDataUsagePopover != nil {
            dailyDataUsagePopover!.close()
        }

        dailyDataUsagePopover = NSPopover()
        dailyDataUsagePopover!.contentSize = contentViewController.view.frame.size
        dailyDataUsagePopover!.behavior = .transient
        dailyDataUsagePopover!.animates = false
        dailyDataUsagePopover!.contentViewController = contentViewController

        dailyDataUsagePopover!.show(relativeTo: event.trackingArea!.rect, of: self, preferredEdge: .maxY)
    }

    override func mouseExited(with event: NSEvent) {
        if let popover = dailyDataUsagePopover {
            popover.close()
            dailyDataUsagePopover = nil
        }
    }
}
