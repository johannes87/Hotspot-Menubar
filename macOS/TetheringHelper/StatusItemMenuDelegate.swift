//
//  StatusItemMenuDelegate.swift
//  TetheringHelper
//
//  Created by Johannes Bittner on 26.09.20.
//  Copyright © 2020 Johannes Bittner. All rights reserved.
//

import Foundation

protocol StatusItemMenuDelegate {
    func sessionBytesTransferredUpdated(bytesTransferred: UInt64)
    func pairingStatusUpdated(pairingStatus: PairingStatus)
}
