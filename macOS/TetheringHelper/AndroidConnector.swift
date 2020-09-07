//
//  AndroidConnector.swift
//  TetheringHelper
//
//  Created by Johannes Bittner on 19.11.19.
//  Copyright © 2019 Johannes Bittner. All rights reserved.
//

import Foundation
import AppKit
import os
import Network


class AndroidConnector: NSObject, NetServiceBrowserDelegate, NetServiceDelegate {
    private(set) var signalQuality = SignalQuality.no_signal
    private(set) var signalType = SignalType.no_signal
    private(set) var localInterfaceName: String?

    var pairingStatus: PairingStatus {
        get {
            if let service = tetheringHelperServiceResolved {
                return PairingStatus.paired(phoneName: service.name)
            } else {
                return PairingStatus.unpaired
            }
        }
    }

    /// `ServiceResponse` is the format of the JSON response sent by the Android device
    private struct ServiceResponse: Codable {
        /// `quality` is the signal quality, the number of signal bars shown on the Android device
        var quality: Int
        /// `type` is the network signal type, e.g. 4G or LTE
        var type: String
    }

    private static let bonjourServiceType = "_tetheringhelper._tcp."

    private let networkQueue = DispatchQueue(label: "network")

    private var tetheringHelperServiceUnresolved: NetService?
    private var tetheringHelperServiceResolved: NetService?
    private var netServiceBrowser: NetServiceBrowser?


    func getSignal() {
        if !pairingStatus.isPaired {
            pair()
            waitFor(timeout: 1.0) { self.pairingStatus.isPaired }
            guard pairingStatus.isPaired else { return }
        }

        fetchSignalFromAndroid()
    }

    private func getInterfaceName(networkConnection: NWConnection) -> String {
        // localEndpoint sometimes has nil as "interface"
        return networkConnection.currentPath!.remoteEndpoint!.interface!.name
    }

    private func fetchSignalFromAndroid() {
        let endpoint = NWEndpoint.hostPort(
            host: NWEndpoint.Host(tetheringHelperServiceResolved!.hostName!),
            port: NWEndpoint.Port(integerLiteral: NWEndpoint.Port.IntegerLiteralType(tetheringHelperServiceResolved!.port)))
        let networkConnection = NWConnection(to: endpoint, using: .tcp)

        networkConnection.stateUpdateHandler = { [unowned networkConnection] state in
            switch state {
            case .ready:
                let interfaceName = self.getInterfaceName(networkConnection: networkConnection)
                os_log(.debug, "Found local interface used for connecting: %@", interfaceName)
                self.localInterfaceName = interfaceName
            case .waiting(_):
                // the waiting state happens when the connection is refused
                os_log(.debug, "Pairing to phone lost")
                self.resetState()
            default:
                break
            }
        }

        var messageReceived = false
        networkConnection.receiveMessage { data, _, messageComplete, error in
            defer {
                // cancel() needs to be called, otherwise networkConnection leaks memory
                networkConnection.cancel()
            }
            if error != nil || !messageComplete {
                return
            }
            self.decodeServiceResponse(forData: data!)
            messageReceived = true
        }

        networkConnection.start(queue: networkQueue)

        // waitFor needed because receiveMessage will run asynchronously, and we want AndroidConnector
        // to have the signal data once this function returns
        waitFor(timeout: 1) { messageReceived }
    }

    private func resetState() {
        self.signalQuality = .no_signal
        self.signalType = .no_signal
        self.tetheringHelperServiceResolved = nil
        self.localInterfaceName = nil
    }

    private func decodeServiceResponse(forData data: Data) {
        let decoder = JSONDecoder()
        let serviceResponse = try! decoder.decode(ServiceResponse.self, from: data)
        self.signalQuality = SignalQuality(rawValue: serviceResponse.quality)!
        self.signalType = SignalType(rawValue: serviceResponse.type)!
    }

    /// `waitFor` will wait synchronously until timeout is reached or condition returns true
    private func waitFor(timeout: TimeInterval, condition: () -> Bool) {
        var timeSlept: TimeInterval = 0
        let sleepDuration: TimeInterval = 0.2

        while timeSlept < timeout {
            if condition() {
                return
            }
            Thread.sleep(forTimeInterval: sleepDuration)
            timeSlept += sleepDuration
        }
        return
    }

    private func pair() {
        tetheringHelperServiceResolved = nil

        // make NetServiceBrowser work by running it in the main thread
        // see https://stackoverflow.com/q/3526661/96205
        DispatchQueue.main.async {
            self.netServiceBrowser = NetServiceBrowser()
            self.netServiceBrowser?.delegate = self
            self.netServiceBrowser?.searchForServices(ofType: AndroidConnector.bonjourServiceType, inDomain: "")
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
