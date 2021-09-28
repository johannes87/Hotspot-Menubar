//
//  PreferencesStorage.swift
//  TetheringHelper
//
//  Created by Johannes Bittner on 19.06.20.
//  Copyright © 2020 Johannes Bittner. All rights reserved.
//

import Foundation

class PreferencesStorage {
    private static let refreshStatusDelayKey = "refreshStatusDelay"

    static var refreshStatusDelay: Int {
        get {
            let defaultRefreshStatusDelay = 5
            let userDefaults = UserDefaults()
            if let refreshStatusDelay = userDefaults.object(forKey: refreshStatusDelayKey) as? Int {
                return refreshStatusDelay
            } else {
                return defaultRefreshStatusDelay
            }
        }
        set {
            let userDefaults = UserDefaults()
            userDefaults.set(newValue, forKey: refreshStatusDelayKey)
        }
    }
}
