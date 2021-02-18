//
//  PhoneSignal.swift
//  TetheringHelper
//
//  Created by Johannes Bittner on 18.02.21.
//  Copyright © 2021 Johannes Bittner. All rights reserved.
//

import Foundation

class PhoneSignal {
    let quality: SignalQuality
    let type: SignalType
    init(quality: SignalQuality, type: SignalType) {
        self.quality = quality
        self.type = type
    }
}
