//
//  AndroidConnector.swift
//  TetheringHelper
//
//  Created by Johannes Bittner on 19.11.19.
//  Copyright © 2019 Johannes Bittner. All rights reserved.
//

import Foundation
import AppKit

class AndroidConnector: NSObject, NetServiceBrowserDelegate, NetServiceDelegate {
    private let netServiceBrowser = NetServiceBrowser()

    private(set) var signalQuality = SignalQuality.no_signal
    private(set) var signalType = SignalType.no_signal

    private var tetheringHelperService: NetService?


    public func getSignal() {
        if tetheringHelperService == nil {
            print("getSignal: no tetheringHelperService; exiting")
            return
        }

        print("getSignal: tetheringHelperService exists")

        var inputStream: InputStream? = InputStream()
        if tetheringHelperService?.getInputStream(&inputStream, outputStream: nil) == false {
            print("getSignal: getInputStream failed. exiting")
            return
        }

        inputStream!.open()
        // TODO: check if .close() is mendatory

        let bufferSize = 256
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        let bytesRead = inputStream!.read(buffer, maxLength: bufferSize)

        if bytesRead <= 0 {
            print("getSignal: unexpected bytesRead = \(String(describing: bytesRead)); exiting")
            return
        }

        buffer[bytesRead] = 0

        // NOTE! data is received correctly, but weird backtrace happens: similar to this => https://forums.developer.apple.com/thread/112967
        // consider using alternative network framework or use sockets directly.

        let bytesString: String = String(cString: buffer)
        print("getSignal: received bytes: \(bytesString)")
    }

    @IBAction public func pair(sender: Any) {
        print("connector pair!")


        tetheringHelperService = nil
        netServiceBrowser.delegate = self
        // stop before searching, because searchForServices otherwise works only once (subsequent searches
        // return activityInProgress error)
        netServiceBrowser.stop()
        netServiceBrowser.searchForServices(ofType: "_tetheringhelper._tcp.", inDomain: "")

        // TODO: show progress icon in status item during pairing

        // show user a message if service couldn't be found
        DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: {
            self.netServiceBrowser.stop()
            if self.tetheringHelperService == nil {
                let alert = NSAlert()
                alert.messageText = NSLocalizedString("No phone could be found for pairing",
                                                      comment: "user clicks 'pair' and phone couldn't be found: NSAlert messageText")
                alert.informativeText = NSLocalizedString("Make sure you are tethered with your Android phone and the TetheringHelper app is running on Android.",
                                                          comment: "explanation what to do when no phone to pair was found")
                alert.runModal()
            }
        })
    }

    // MARK: NetServiceBrowserDelegate

    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        print("Discovered the service")
        print("- name:", service.name)
        print("- type", service.type)
        print("- domain:", service.domain)

        tetheringHelperService = service
        tetheringHelperService?.delegate = self
    }
    }

    // MARK: NetServiceDelegate
    }
}
