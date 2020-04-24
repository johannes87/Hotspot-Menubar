//
//  AndroidConnector.swift
//  TetheringHelper
//
//  Created by Johannes Bittner on 19.11.19.
//  Copyright © 2019 Johannes Bittner. All rights reserved.
//

import Foundation
import AppKit
import Socket

class AndroidConnector: NSObject, NetServiceBrowserDelegate, NetServiceDelegate {
    private(set) var signalQuality = SignalQuality.no_signal
    private(set) var signalType = SignalType.no_signal

    private var tetheringHelperServiceUnresolved: NetService?
    private var tetheringHelperServiceResolved: NetService?

    private unowned var statusItem: StatusItem?


    func getSignal() {
        guard tetheringHelperServiceResolved != nil else { return }

        var serviceResponse: String
        do {
            let socket = try Socket.create()
            try socket.connect(to: (tetheringHelperServiceResolved?.hostName)!, port: Int32((tetheringHelperServiceResolved?.port)!))
            serviceResponse = try socket.readString()!
            socket.close()
        } catch let error {
            print("Could not communicate with service: \(error)")
            return
        }

        print("Read data from service: \(serviceResponse)")
    }

    func setStatusItem(_ statusItem: StatusItem) {
        self.statusItem = statusItem
    }

    @IBAction func pair(sender: Any) {
        tetheringHelperServiceResolved = nil

        let netServiceBrowser = NetServiceBrowser()
        netServiceBrowser.delegate = self
        netServiceBrowser.searchForServices(ofType: "_tetheringhelper._tcp.", inDomain: "")

        statusItem?.startPairingProgressAnimation()
        alertPairingFailed(netServiceBrowser, timeout: 3)
    }

    private func alertPairingFailed(_ netServiceBrowser: NetServiceBrowser, timeout: TimeInterval) {
        DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
            self.statusItem?.stopPairingProgressAnimation()
            netServiceBrowser.stop()
            if self.tetheringHelperServiceResolved == nil {
                let alert = NSAlert()
                alert.messageText = NSLocalizedString("No phone could be found for pairing",
                                                      comment: "user clicks 'pair' and phone couldn't be found: NSAlert messageText")
                alert.informativeText = NSLocalizedString("Make sure you are tethered with your Android phone and the TetheringHelper app is running on Android.",
                                                          comment: "explanation what to do when no phone to pair was found")
                alert.runModal()
            }
        }
    }

    // MARK: NetServiceBrowserDelegate
    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        print("Discovered the service: name=\(service.name), type=\(service.type)")
        // without this variable, the service goes out of scope and no delegate gets called
        tetheringHelperServiceUnresolved = service
        service.delegate = self
        service.resolve(withTimeout: 1)
    }

    // MARK: NetServiceDelegate
    func netServiceDidResolveAddress(_ sender: NetService) {
        tetheringHelperServiceResolved = sender
        statusItem?.stopPairingProgressAnimation()
    }
}
