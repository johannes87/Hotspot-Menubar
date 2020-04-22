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
    private(set) var signalQuality = SignalQuality.no_signal
    private(set) var signalType = SignalType.no_signal

    private var tetheringHelperServiceUnresolved: NetService?
    private var tetheringHelperServiceResolved: NetService?

    private func alertPairingFailed(_ netServiceBrowser: NetServiceBrowser, timeout: TimeInterval) {
        DispatchQueue.main.asyncAfter(deadline: .now() + timeout, execute: {
            netServiceBrowser.stop()
            if self.tetheringHelperServiceResolved == nil {
                let alert = NSAlert()
                alert.messageText = NSLocalizedString("No phone could be found for pairing",
                                                      comment: "user clicks 'pair' and phone couldn't be found: NSAlert messageText")
                alert.informativeText = NSLocalizedString("Make sure you are tethered with your Android phone and the TetheringHelper app is running on Android.",
                                                          comment: "explanation what to do when no phone to pair was found")
                alert.runModal()
            }
        })
    }

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
        tetheringHelperServiceResolved = nil

        let netServiceBrowser = NetServiceBrowser()
        netServiceBrowser.delegate = self
        netServiceBrowser.searchForServices(ofType: "_tetheringhelper._tcp.", inDomain: "")

        // TODO: show progress icon in status item during pairing
        alertPairingFailed(netServiceBrowser, timeout: 3)
    }

    // MARK: NetServiceBrowserDelegate
    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        print("Discovered the service: name=\(service.name), type=\(service.type)")
        // without this, the service goes out of scope and no delegate gets called
        tetheringHelperServiceUnresolved = service
        service.delegate = self
        service.resolve(withTimeout: 1)
    }

    // MARK: NetServiceDelegate
    func netServiceDidResolveAddress(_ sender: NetService) {
        tetheringHelperServiceResolved = sender
    }
}
