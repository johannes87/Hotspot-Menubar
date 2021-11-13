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

/// AndroidConnector discovers the Android device and fetches the signal from it
///
/// NSObject base class is needed for service discovery
class AndroidConnector: NSObject {
    private(set) var tetheringInterfaceName: String?
    private(set) var pairingStatus: PairingStatus = PairingStatus.unpaired

    /// `ServiceResponse` is the format of the JSON response sent by the Android device
    private struct ServiceResponse: Codable {
        /// `quality` is the signal quality, the number of signal bars shown on the Android device
        var quality: Int
        /// `type` is the network signal type, e.g. 4G or LTE
        var type: String
    }

    private let networkQueue = DispatchQueue(label: "network")

    private var phoneServiceUnresolved: NetService?
    private var phoneService: NetService?
    private var netServiceBrowser: NetServiceBrowser?

    private var statusItemDelegate: StatusItemDelegate!
    private var statusItemMenuDelegate: StatusItemMenuDelegate!


    init(statusItemDelegate: StatusItemDelegate, statusItemMenuDelegate: StatusItemMenuDelegate) {
        super.init()
        self.statusItemDelegate = statusItemDelegate
        self.statusItemMenuDelegate = statusItemMenuDelegate
    }

    func getSignal() {
        var phoneSignal: PhoneSignal? = nil
        var pairingStatus: PairingStatus = .unpaired

        defer {
            self.pairingStatus = pairingStatus
            self.statusItemDelegate.signalUpdated(phoneSignal: phoneSignal)
            self.statusItemDelegate.pairingStatusUpdated(pairingStatus: self.pairingStatus)
            self.statusItemMenuDelegate.pairingStatusUpdated(pairingStatus: self.pairingStatus)
        }

        if phoneService == nil {
            discoverPhone()
            Utils.waitFor(timeout: 1.0) { self.phoneService != nil }
            guard self.phoneService != nil else { return }
        }

        phoneSignal = fetchSignalFromAndroid()
        if phoneSignal != nil {
            pairingStatus = .paired(phoneName: phoneService!.name)
        } else {
            // if no phone signal is returned, we want the phone discovery process to start again next time
            phoneService = nil
        }
    }

    /// getInterfaceName returns the network interface that is used for connecting to the Android device
    ///
    /// The interface is needed to measure the amount of data transferred
    private func getInterfaceName(forConnection networkConnection: NWConnection) -> String {
        // localEndpoint sometimes has nil as "interface", so we use remoteEndpoint
        return networkConnection.currentPath!.remoteEndpoint!.interface!.name
    }

    private func fetchSignalFromAndroid() -> PhoneSignal? {
        let endpoint = NWEndpoint.hostPort(
            host: NWEndpoint.Host(phoneService!.hostName!),
            port: NWEndpoint.Port(integerLiteral: NWEndpoint.Port.IntegerLiteralType(phoneService!.port)))
        let networkConnection = NWConnection(to: endpoint, using: .tcp)
        var phoneSignal: PhoneSignal? = nil

        networkConnection.stateUpdateHandler = { [unowned networkConnection] state in
            switch state {
            case .ready:
                self.tetheringInterfaceName = self.getInterfaceName(forConnection: networkConnection)
            case .waiting(_):
                // the waiting state happens when the connection is refused
                os_log(.debug, "Connection to phone lost")
            default:
                break
            }
        }

        networkConnection.receiveMessage { data, _, messageComplete, error in
            defer {
                // cancel() needs to be called, otherwise networkConnection leaks memory
                networkConnection.cancel()
            }
            if error != nil || !messageComplete {
                return
            }

            let decoder = JSONDecoder()

            if let serviceResponse = try? decoder.decode(ServiceResponse.self, from: data!) {
                phoneSignal = PhoneSignal(
                    quality: SignalQuality(rawValue: serviceResponse.quality)!,
                    type: SignalType(rawValue: serviceResponse.type)!
                )
            } else {
                os_log(.debug, "Unexpected data received: %@", String(decoding: data!, as: UTF8.self))
            }
        }

        networkConnection.start(queue: networkQueue)

        // waitFor needed because receiveMessage will run asynchronously, and we want AndroidConnector
        // to have the signal data once this function returns
        Utils.waitFor(timeout: 1.0) { phoneSignal != nil }
        return phoneSignal
    }
}

extension AndroidConnector: NetServiceBrowserDelegate, NetServiceDelegate {
    private static let bonjourServiceType = "_tetheringhelper._tcp."

    private func discoverPhone() {
        phoneService = nil

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
        phoneServiceUnresolved = service
        phoneServiceUnresolved?.delegate = self
        phoneServiceUnresolved?.resolve(withTimeout: 1)
    }

    // MARK: NetServiceDelegate
    func netServiceDidResolveAddress(_ sender: NetService) {
        phoneService = sender
    }
}
