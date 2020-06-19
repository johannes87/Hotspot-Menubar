//
//  PreferencesStorage.swift
//  TetheringHelper
//
//  Created by Johannes Bittner on 19.06.20.
//  Copyright © 2020 Johannes Bittner. All rights reserved.
//

import Foundation

class PreferencesStorage {
    private static let defaultRefreshStatusDelay = 5
    private static let refreshStatusDelayKey = "refreshStatusDelay"


    static func getRefreshStatusDelay() -> Int {
        let userDefaults = UserDefaults()
        if let refreshStatusDelay = userDefaults.object(forKey: refreshStatusDelayKey) as? Int {
            return refreshStatusDelay
        } else {
            return defaultRefreshStatusDelay
        }
    }

    static func setRefreshStatusDelay(newValue: Int) {
        let userDefaults = UserDefaults()
        userDefaults.set(newValue, forKey: refreshStatusDelayKey)
    }
}
