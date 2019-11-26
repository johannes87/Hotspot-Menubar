//
//  AndroidConnector.swift
//  TetheringHelper
//
//  Created by Johannes Bittner on 19.11.19.
//  Copyright © 2019 Johannes Bittner. All rights reserved.
//

import Foundation

class AndroidConnector {
    private(set) var signalQuality = SignalQuality.no_signal
    private(set) var signalType = SignalType.no_signal
    
    public func updateSignal() {
        fetchSignal()
    }

    private func fetchSignal() {
        // TODO fetch data from android here
        signalQuality = SignalQuality.allCases.randomElement()!
        signalType = SignalType.allCases.randomElement()!
    }
}
