//
//  SessionTracker.swift
//  Hotspot Menubar
//
//  Created by Johannes Bittner on 01.08.20.
//  Copyright © 2020 Johannes Bittner. All rights reserved.
//

import Foundation
import CoreData
import os

enum GetBytesTransferredError: Error {
    case getifaddrsFailed
    case noDataFound
}

typealias IfaddrsBytesTransferred = (inputBytes: UInt32, outputBytes: UInt32)

/// SessionTracker's responsibility is to determine when a tethering session with a phone starts and ends, determine the amount
/// of data transferred in a session, and persistently store that information via PersistentContainer
class SessionTracker {
    private(set) var bytesTransferred: UInt64 = 0
    private(set) var sessionActive = false

    private let statusItemMenuDelegate: StatusItemMenuDelegate

    private var lastIfaddrsBytesTransferred: IfaddrsBytesTransferred = (0, 0)
    private var currentTetheringSession: TetheringSession?

    init(statusItemMenuDelegate: StatusItemMenuDelegate) {
        self.statusItemMenuDelegate = statusItemMenuDelegate
    }

    func trackSession(pairingStatus: PairingStatus, localInterfaceName: String?) {
        if pairingStatus.isPaired {
            if localInterfaceName == nil {
                // tetheringInterfaceName in AndroidConnector might not be set. We need it to track the session.
                return
            }

            let ifaddrsBytesTransferred = try! getIfaddrsBytesTransferred(forInterface: localInterfaceName!)

            if !sessionActive {
                createSession(
                    phoneName: pairingStatus.phoneName!,
                    ifaddrsBytesTransferred: ifaddrsBytesTransferred
                )
            } else {
                updateSession(ifaddrsBytesTransferred: ifaddrsBytesTransferred)
            }
        } else if sessionActive {
            closeSession()
        }
    }

    private func createSession(phoneName: String, ifaddrsBytesTransferred: IfaddrsBytesTransferred) {
        os_log(.debug, "Starting session to %@", phoneName)
        sessionActive = true
        lastIfaddrsBytesTransferred = ifaddrsBytesTransferred
        currentTetheringSession = PersistentContainer.shared.createNewTetheringSession(
            withPhoneName: phoneName
        )
    }

    private func updateSession(ifaddrsBytesTransferred: IfaddrsBytesTransferred) {
        let inputBytesDifference = getBytesTransferredDifference(
            bytesPast: lastIfaddrsBytesTransferred.inputBytes,
            bytesNow: ifaddrsBytesTransferred.inputBytes)
        let outputBytesDifference = getBytesTransferredDifference(
            bytesPast: lastIfaddrsBytesTransferred.outputBytes,
            bytesNow: ifaddrsBytesTransferred.outputBytes)

        bytesTransferred += UInt64(inputBytesDifference) + UInt64(outputBytesDifference)

        PersistentContainer.shared.updateTetheringSession(
            currentTetheringSession!,
            withBytesTransferred: Int64(bytesTransferred)
        )

        os_log(.debug, "Transferred %f MB this session", Double(bytesTransferred) / 1024 / 1024)
        lastIfaddrsBytesTransferred = ifaddrsBytesTransferred
    }

    private func closeSession() {
        os_log(.debug, "Session lost")
        sessionActive = false
        lastIfaddrsBytesTransferred = (0, 0)
        bytesTransferred = 0
        currentTetheringSession = nil
    }

    private func getBytesTransferredDifference(bytesPast: UInt32, bytesNow: UInt32) -> UInt32 {
        if Int64(bytesNow) - Int64(bytesPast) < 0 {
            // Handle wrap-around. This happens when ibytes/obytes that is returned by getifaddrs wrap around the UInt32.max boundary
            return (UInt32.max - bytesPast) + bytesNow
        } else {
            return bytesNow - bytesPast
        }
    }

    /// Get the bytes transferred on `interface`, as reported by `getifaddrs`
    ///
    /// This is the only way to retrieve this information.
    /// See this thread: https://developer.apple.com/forums/thread/81833?answerId=246160022#246160022
    ///
    /// Parameter `forInterface`: The interface for which to acquire the number of bytes transferred
    /// Returns: a tuple with two UInt32, which corresponds to `getifaddrs`'s `ifi_ibytes` and `ifi_obytes`
    private func getIfaddrsBytesTransferred(forInterface: String) throws -> IfaddrsBytesTransferred {
        // the initial pointer is needed so it can be passed to "freeifaddrs" at the end
        var initialIfaddrs: UnsafeMutablePointer<ifaddrs>!

        var foundData = false

        let returnCode = getifaddrs(&initialIfaddrs)
        if returnCode != 0 {
            throw GetBytesTransferredError.getifaddrsFailed
        }

        defer {
            if initialIfaddrs != nil {
                freeifaddrs(initialIfaddrs)
            }
        }

        var currentIfaddrs: UnsafeMutablePointer<ifaddrs>! = initialIfaddrs

        while currentIfaddrs != nil {
            defer {
                currentIfaddrs = currentIfaddrs.pointee.ifa_next
            }

            let ifa_name = String(cString: currentIfaddrs.pointee.ifa_name)

            if ifa_name != forInterface {
                continue
            }

            if currentIfaddrs.pointee.ifa_data != nil {
                // We found the data we wanted, we can return
                let ifa_data = currentIfaddrs.pointee.ifa_data.assumingMemoryBound(to: if_data.self)
                foundData = true
                return (ifa_data.pointee.ifi_ibytes, ifa_data.pointee.ifi_obytes)
            }
        }

        if !foundData {
            throw GetBytesTransferredError.noDataFound
        }
    }
}
