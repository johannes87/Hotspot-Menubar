//
//  StatusItemDelegate.swift
//  TetheringHelper
//
//  Created by Johannes Bittner on 26.09.20.
//  Copyright © 2020 Johannes Bittner. All rights reserved.
//

import Foundation

protocol StatusItemDelegate {
    func signalUpdated(signalQuality: SignalQuality, signalType: SignalType)
    func pairingStatusUpdated(pairingStatus: PairingStatus)
}
