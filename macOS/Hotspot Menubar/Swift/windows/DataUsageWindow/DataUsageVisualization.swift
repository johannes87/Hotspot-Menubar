//
//  DataUsageVisualization.swift
//  Hotspot Menubar
//
//  Created by Johannes Bittner on 29.06.21.
//  Copyright © 2021 Johannes Bittner. All rights reserved.
//

import Cocoa
import CoreGraphics

private let trackingAreaKeyDataUsage = "dataUsage"

@IBDesignable
class DataUsageVisualization : NSView {
    /// The data that is shown in the chart
    ///
    /// - Note: Initial value set to show chart in storyboard (IBDesignable)
    var dataUsage: [DataUsage]? = [DataUsage(bytesTransferred: 1000000, date: Date())] {
        didSet {
            needsDisplay = true
        }
    }

    private var dayUsagePopover: NSPopover?
    private var dayUsagePopoverTimer: Timer?

    private let popoverDateFormatter = DateFormatter()
    private let dayUsagePopoverDelay: TimeInterval = 0.5


    required init?(coder: NSCoder) {
        super.init(coder: coder)
        popoverDateFormatter.calendar = Calendar(identifier: .gregorian)
        popoverDateFormatter.dateStyle = .medium
        popoverDateFormatter.timeStyle = .none
    }

    override func draw(_ dirtyRect: NSRect) {
        guard
            let unwrappedDataUsage = dataUsage,
            let maxUsageInMonth = unwrappedDataUsage.max()?.bytesTransferred
        else { return }

        let daysInMonth = unwrappedDataUsage.count

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
            let dayDataUsage = unwrappedDataUsage[day - 1]
            
            var barHeight = 0
            if dayDataUsage.bytesTransferred > 0 {
                barHeight = Int((Double(dayDataUsage.bytesTransferred) / Double(maxUsageInMonth)) * Double(maxBarHeight))
                
                // barHeight might be rounded to 0 for small `bytesTransferred`; make its height at least 2 points
                barHeight = barHeight < 2 ? 2 : barHeight
            }
            
            // Draw the bar showing the data usage for a day
            let barRect = NSRect(
                x: dayXPos,
                y: labelHeight + marginYBetweenBarAndLabel,
                width: barWidth,
                height: barHeight
            )
            barChartPath.appendRoundedRect(barRect, xRadius: 5.0, yRadius: 5.0)

            // Make tracking rect slightly higher for easier selection and aesthetics
            if barRect.height > 0 {
                var trackingRect = barRect
                trackingRect.size.height += 5

                addTrackingArea(
                    NSTrackingArea(
                        rect: trackingRect,
                        options: [.activeAlways, .mouseEnteredAndExited],
                        owner: self,
                        userInfo: [trackingAreaKeyDataUsage: dayDataUsage])
                )
            }

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

    private func showDayUsagePopover(forDataUsage dataUsage: DataUsage, onRect chartBarRect: NSRect) {
        let popoverTextTemplate = NSLocalizedString("%@ on %@",
                                                    comment: "text shown in popover in data usage window, e.g. '2.34 MB on 4. Oct 2021'")
        let popoverText = String(format: popoverTextTemplate,
                                 Utils.byteCountFormatter.string(fromByteCount: dataUsage.bytesTransferred),
                                 popoverDateFormatter.string(from: dataUsage.date!))

        let contentViewController = NSViewController()
        contentViewController.view = NSView()

        let textField = NSTextField(labelWithAttributedString: NSAttributedString(
            string: popoverText,
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

        if dayUsagePopover != nil {
            dayUsagePopover!.close()
        }

        dayUsagePopover = NSPopover()
        dayUsagePopover!.contentSize = contentViewController.view.frame.size
        dayUsagePopover!.behavior = .transient
        dayUsagePopover!.animates = true
        dayUsagePopover!.contentViewController = contentViewController

        // ensure the popover is shown inside the view
        var preferredEdge: NSRectEdge
        let popoverDecorationSize: CGFloat = 15
        if contentViewController.view.frame.width + popoverDecorationSize > chartBarRect.origin.x {
            preferredEdge = .maxX
        } else {
            preferredEdge = .minX
        }

        dayUsagePopover!.show(relativeTo: chartBarRect, of: self, preferredEdge: preferredEdge)
    }

    override func mouseEntered(with event: NSEvent) {
        if let timer = dayUsagePopoverTimer {
            timer.invalidate()
            dayUsagePopoverTimer = nil
        }

        dayUsagePopoverTimer = Timer.scheduledTimer(
            withTimeInterval: TimeInterval(dayUsagePopoverDelay),
            repeats: false
        ) { _ in
            self.showDayUsagePopover(
                forDataUsage: event.trackingArea?.userInfo?[trackingAreaKeyDataUsage]! as! DataUsage,
                onRect: event.trackingArea!.rect
            )
        }
    }

    override func mouseExited(with event: NSEvent) {
        // don't show popover when mouse already has left the tracking rect
        if let timer = dayUsagePopoverTimer {
            timer.invalidate()
            dayUsagePopoverTimer = nil
        }

        if let popover = dayUsagePopover {
            popover.close()
            dayUsagePopover = nil
        }
    }
}
