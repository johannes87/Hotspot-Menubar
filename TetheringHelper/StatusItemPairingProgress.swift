//
//  StatusItemPairingProgress.swift
//  TetheringHelper
//
//  Created by Johannes Bittner on 23.04.20.
//  Copyright © 2020 Johannes Bittner. All rights reserved.
//

import Foundation

class StatusItemPairingProgress {
    private static let animationInterval = 0.3

    private unowned let statusItem: StatusItem

    private var currentSignalQualityAnimation = 0
    private var animationTimer: Timer?
    

    init(statusItem: StatusItem) {
        self.statusItem = statusItem
    }

    func startAnimation() {
        animationTimer = Timer.scheduledTimer(
            withTimeInterval: StatusItemPairingProgress.animationInterval,
            repeats: true) { _ in
                self.animationTick()
        }
    }

    func stopAnimation() {
        animationTimer?.invalidate()
    }

    private func animationTick() {
        statusItem.setSignal(
            signalQuality: SignalQuality(rawValue: currentSignalQualityAnimation)!,
            signalType: SignalType.no_signal
        )

        currentSignalQualityAnimation += 1
        currentSignalQualityAnimation %= SignalQuality.allCases.count
    }
}
