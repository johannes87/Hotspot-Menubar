//
//  SessionTracker.swift
//  TetheringHelper
//
//  Created by Johannes Bittner on 01.08.20.
//  Copyright © 2020 Johannes Bittner. All rights reserved.
//

import Foundation
import CoreData

enum GetBytesTransferredError: Error {
    case getifaddrsFailed
    case noDataFound
}

class SessionTracker {
    var sessionBytesTransferred: UInt64 = 0

    private var sessionActive = false
    private var lastBytesTransferred: (inputBytes: UInt32, outputBytes: UInt32) = (0, 0)

    private lazy var persistentContainer: NSPersistentContainer = {
        // TODO: rename DataModel to something specific, e.g. SessionStorage.xcdatamodeld
        let container = NSPersistentContainer(name: "DataModel")
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Unable to load persistent stores: \(error)")
            }
        }
        return container
    }()


    func trackSession(pairingStatus: PairingStatus, localInterfaceName: String?) {
        if pairingStatus.isPaired {
            if localInterfaceName == nil {
                // We can't track the session if there's no interface
                return
            }

            let bytesTransferred = try! getBytesTransferred(forInterface: localInterfaceName!)

            if !sessionActive {
                print("Starting session to \(String(describing: pairingStatus.phoneName))")
                sessionActive = true
                lastBytesTransferred = bytesTransferred
            } else {
                let inputBytesDifference = getBytesTransferredDifference(
                    bytesPast: lastBytesTransferred.inputBytes,
                    bytesNow: bytesTransferred.inputBytes)
                let outputBytesDifference = getBytesTransferredDifference(
                    bytesPast: lastBytesTransferred.outputBytes,
                    bytesNow: bytesTransferred.outputBytes)
                sessionBytesTransferred += UInt64(inputBytesDifference) + UInt64(outputBytesDifference)


                print("Transferred \(Double(sessionBytesTransferred) / 1024 / 1024) MB this session")
                lastBytesTransferred = bytesTransferred
            }
        } else if sessionActive {
            print("Session lost")
            sessionActive = false
            lastBytesTransferred = (0, 0)
            sessionBytesTransferred = 0
        }
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
    private func getBytesTransferred(forInterface: String) throws -> (inputBytes: UInt32, outputBytes: UInt32) {
        // the initial pointer is needed so it can be passwd to "freeifaddrs" at the end
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
