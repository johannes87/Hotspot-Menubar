//
//  Utils.swift
//  TetheringHelper
//
//  Created by Johannes Bittner on 18.02.21.
//  Copyright © 2021 Johannes Bittner. All rights reserved.
//

import Foundation

class Utils {
    /// `waitFor` will wait synchronously until timeout is reached or condition returns true
    static func waitFor(timeout: TimeInterval, condition: () -> Bool) {
        var timeSlept: TimeInterval = 0
        let sleepDuration: TimeInterval = 0.1

        while timeSlept < timeout {
            if condition() {
                return
            }
            Thread.sleep(forTimeInterval: sleepDuration)
            timeSlept += sleepDuration
        }
        return
    }
}
