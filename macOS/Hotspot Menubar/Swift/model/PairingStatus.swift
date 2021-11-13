//
//  PairingStatus.swift
//  Hotspot Menubar
//
//  Created by Johannes Bittner on 01.05.20.
//  Copyright © 2020 Johannes Bittner. All rights reserved.
//

import Foundation

enum PairingStatus {
    case paired(phoneName: String)
    case unpaired

    var isPaired: Bool {
        switch self {
        case .paired(_): return true
        case .unpaired: return false
        }
    }

    var phoneName: String? {
        switch self {
        case .paired(let phoneName): return phoneName
        case .unpaired: return nil
        }
    }
}
