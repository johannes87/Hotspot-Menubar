//
//  PreferencesStorage.swift
//  Hotspot Menubar
//
//  Created by Johannes Bittner on 19.06.20.
//  Copyright © 2020 Johannes Bittner. All rights reserved.
//

import Foundation

class PreferencesStorage {
    private static let defaults = UserDefaults.standard
    private static let transferNotifyAfterMegabytesKey = "transferNotifyAfterMegabytes"
    private static let enableTransferNotificationKey = "enableTransferNotification"

    static var transferNotifyAfterMegabytes: Double? {
        get {
            return defaults.object(forKey: transferNotifyAfterMegabytesKey) as? Double
        }
    }

    static var enableTransferNotification: Bool? {
        get {
            return defaults.object(forKey: enableTransferNotificationKey) as? Bool
        }
    }

    static func registerDefaults() {
        defaults.register(defaults: [
            transferNotifyAfterMegabytesKey: 50.0,
            enableTransferNotificationKey: false,
        ])
    }
}
