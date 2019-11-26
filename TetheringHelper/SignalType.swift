//
//  SignalType.swift
//  TetheringHelper
//
//  Created by Johannes Bittner on 19.11.19.
//  Copyright © 2019 Johannes Bittner. All rights reserved.
//

import Foundation

// TODO: CaseIterable for testing, remove
enum SignalType: String, CaseIterable {
    case no_signal = ""
    case two_g = "2G"
    case edge = "E"
    case three_g = "3G"
    case hsdpa = "H"
    case lte = "LTE"
    case five_g = "5G"
}
