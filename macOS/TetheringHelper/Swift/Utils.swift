//
//  Utils.swift
//  TetheringHelper
//
//  Created by Johannes Bittner on 18.02.21.
//  Copyright © 2021 Johannes Bittner. All rights reserved.
//

import Foundation
import AppKit

class Utils {
    /// `waitFor` will wait synchronously until timeout is reached or condition returns true
    static func waitFor(timeout: TimeInterval, condition: () -> Bool) {
        var timeSlept: TimeInterval = 0
        let sleepDuration: TimeInterval = 0.1

        while timeSlept < timeout {
            if condition() {
                return
            }
            Thread.sleep(forTimeInterval: sleepDuration)
            timeSlept += sleepDuration
        }
        return
    }

    // adapted from https://www.hackingwithswift.com/example-code/media/how-to-create-a-qr-code
    static func generateQRCode(from string: String) -> NSImage? {
        let data = string.data(using: String.Encoding.ascii)

        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            let transform = CGAffineTransform(scaleX: 9, y: 9)

            if let output = filter.outputImage?.transformed(by: transform) {
                let rep = NSCIImageRep(ciImage: output)
                let nsImage = NSImage(size: rep.size)
                nsImage.addRepresentation(rep)
                return nsImage
            }
        }

        return nil
    }
    
    static let byteCountFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        return formatter
    }()
}
