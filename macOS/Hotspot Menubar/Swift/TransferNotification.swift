//
//  TransferNotification.swift
//  Hotspot Menubar
//
//  Created by Johannes Bittner on 05.12.21.
//

import Foundation
import UserNotifications
import os

/// TransferNotification's responsibility is to show the user a notification on how much data they transferred.
class TransferNotification {
    private var lastNotificationShownAtBytes: UInt64 = 0

    init() {
        requestNotificationAuthorization()
    }

    func maybeShowNotification(
        sessionActive: Bool,
        bytesTransferred: UInt64
    ) {
        if !sessionActive {
            lastNotificationShownAtBytes = 0
            return
        }

        if PreferencesStorage.enableTransferNotification == false {
            return
        }

        guard let transferNotifyAfterMegabytes = PreferencesStorage.transferNotifyAfterMegabytes else {
            return
        }

        let transferNotifyAfterBytes = UInt64(transferNotifyAfterMegabytes) * 1024 * 1024
        if bytesTransferred > (lastNotificationShownAtBytes + transferNotifyAfterBytes) {
            showNotification(forBytesTransferred: bytesTransferred)
            lastNotificationShownAtBytes = bytesTransferred
        }
    }

    private func showNotification(forBytesTransferred bytesTransferred: UInt64) {
        let content = UNMutableNotificationContent()

        content.title = NSLocalizedString(
            "Data transfer information",
            comment: "transfer notification title")

        content.body = String(format:
                                NSLocalizedString(
                                    "You transferred %@ in this session",
                                    comment: "transfer notification body"),
                              Utils.byteCountFormatter.string(
                                fromByteCount: Int64(bytesTransferred)))

        UNUserNotificationCenter.current().add(
            UNNotificationRequest(
                identifier: UUID().uuidString,
                content: content,
                trigger: nil))
    }

    private func requestNotificationAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge]) {
            granted, error in
            os_log(.debug, "Notification authorization request granted: %@", String(granted))
        }
    }
}

