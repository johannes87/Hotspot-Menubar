//
//  PairingStatus.swift
//  TetheringHelper
//
//  Created by Johannes Bittner on 01.05.20.
//  Copyright © 2020 Johannes Bittner. All rights reserved.
//

import Foundation

enum PairingStatus {
    case paired(phoneName: String)
    case unpaired

    var isPaired: Bool {
        get {
            switch self {
                case .paired(_): return true
                case .unpaired: return false
            }
        }
    }
}
