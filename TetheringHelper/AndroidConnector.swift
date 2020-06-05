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
import os

class AndroidConnector: NSObject, NetServiceBrowserDelegate, NetServiceDelegate {
    private struct ServiceResponse: Codable {
        var quality: Int
        var type: String
    }

    private(set) var signalQuality = SignalQuality.no_signal
    private(set) var signalType = SignalType.no_signal

    var pairingStatus: PairingStatus {
        get {
            if let service = tetheringHelperServiceResolved {
                return PairingStatus.paired(phoneName: service.name)
            } else {
                return PairingStatus.unpaired
            }
        }
    }

    private var tetheringHelperServiceUnresolved: NetService?
    private var tetheringHelperServiceResolved: NetService?
    private var netServiceBrowser: NetServiceBrowser?


    private static func fetchAndDecodeServiceResponse(hostName: String, port: Int) throws -> ServiceResponse {
        let socket = try Socket.create()
        try socket.connect(to: hostName, port: Int32(port))
        let serviceResponseJson = try socket.readString()!

        let decoder = JSONDecoder()
        let serviceResponse = try decoder.decode(ServiceResponse.self, from: serviceResponseJson.data(using: .utf8)!)

        return serviceResponse
    }

    func getSignal() {
        if !pairingStatus.isPaired {
            pair()
            guard waitForPairing(timeout: 1.0) else { return }
        }

        do {
            let serviceResponse = try AndroidConnector.fetchAndDecodeServiceResponse(
                hostName: tetheringHelperServiceResolved!.hostName!,
                port: tetheringHelperServiceResolved!.port)
            signalQuality = SignalQuality(rawValue: serviceResponse.quality)!
            signalType = SignalType(rawValue: serviceResponse.type)!
            os_log(.info, "Got signal from device: quality=%@, type=%@", String(describing: signalQuality), String(describing: signalType))
        } catch let error {
            os_log(.debug, "Could not get signal from android device: %@", String(describing: error))
            signalQuality = SignalQuality.no_signal
            signalType = SignalType.no_signal
            tetheringHelperServiceResolved = nil
        }
    }

    /// waitForPairing will return true if the pairing was successful, or false if it did not succeed before the timeout was reached
    private func waitForPairing(timeout: TimeInterval) -> Bool {
        var timeSlept: TimeInterval = 0
        let sleepDuration: TimeInterval = 0.2

        while timeSlept < timeout {
            if pairingStatus.isPaired {
                return true
            }
            Thread.sleep(forTimeInterval: sleepDuration)
            timeSlept += sleepDuration
        }
        return false
    }

    private func pair() {
        tetheringHelperServiceResolved = nil

        // make NetServiceBrowser work by running it in the main thread
        // see https://stackoverflow.com/q/3526661/96205
        DispatchQueue.main.async {
            self.netServiceBrowser = NetServiceBrowser()
            self.netServiceBrowser?.delegate = self
            self.netServiceBrowser?.searchForServices(ofType: "_tetheringhelper._tcp.", inDomain: "")
        }
    }

    // MARK: NetServiceBrowserDelegate
    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        os_log(.info, "Discovered device: %@", service.name)

        // without this variable, the service goes out of scope and no delegate gets called
        tetheringHelperServiceUnresolved = service
        tetheringHelperServiceUnresolved?.delegate = self
        tetheringHelperServiceUnresolved?.resolve(withTimeout: 1)
    }

    // MARK: NetServiceDelegate
    func netServiceDidResolveAddress(_ sender: NetService) {
        tetheringHelperServiceResolved = sender
    }
}
