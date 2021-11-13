//
//  Autostart.swift
//  TetheringHelper
//
//  Created by Johannes Bittner on 23.06.20.
//  Copyright © 2020 Johannes Bittner. All rights reserved.
//

import Cocoa
import ServiceManagement
import os

class Autostart {
    private static var helperBundleName = "com.gmail.bittner.johannes.Hotspot-Menubar-Autostart"

    static func setAutostart(enabled: Bool) {
        os_log("Setting autostart of %{public}@ to %{public}@", helperBundleName, String(describing: enabled))
        SMLoginItemSetEnabled(helperBundleName as CFString, enabled)
    }

    static func isEnabled() -> Bool {
        let foundHelper = NSWorkspace.shared.runningApplications.contains {
            $0.bundleIdentifier == helperBundleName
        }
        os_log("Found autostart helper: %{public}@", String(describing: foundHelper))
        return foundHelper
    }
}
