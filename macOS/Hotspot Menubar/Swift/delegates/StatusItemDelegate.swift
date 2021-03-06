//
//  StatusItemDelegate.swift
//  Hotspot Menubar
//
//  Created by Johannes Bittner on 26.09.20.
//  Copyright © 2020 Johannes Bittner. All rights reserved.
//

import Foundation

protocol StatusItemDelegate {
    func signalUpdated(phoneSignal: PhoneSignal?)
    func pairingStatusUpdated(pairingStatus: PairingStatus)
}
