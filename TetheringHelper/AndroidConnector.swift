//
//  AndroidConnector.swift
//  TetheringHelper
//
//  Created by Johannes Bittner on 19.11.19.
//  Copyright © 2019 Johannes Bittner. All rights reserved.
//

import Foundation
import Network
import AppKit

class AndroidConnector {
    private(set) var signalQuality = SignalQuality.no_signal
    private(set) var signalType = SignalType.no_signal

    private var paired = false
    private var androidIP: IPAddress = IPv4Address("0.0.0.0")!

    public func getSignal() {
        if paired {

//            let json = getJSONFromAndroid()
//            let json = JSONSerialization.jsonObject(with: data, options: [])
            

        }

        // TODO fetch data from android here
        signalQuality = SignalQuality.allCases.randomElement()!
        signalType = SignalType.allCases.randomElement()!
    }

    @IBAction public func pair(sender: Any) {
        print("connector pair!")

        
    }


    private func createNSAlertFooTODO() {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("Would you like to remember this pairing?",
                                              comment: "pair phone NSAlert")
        alert.informativeText = NSLocalizedString("When you choose to remember the pairing, TetheringHelper will automatically connect to the phone when it is available. You can later reset your choices in the preferences.",
                                                  comment: "pair phone NSAlert")
        alert.alertStyle = .informational
        alert.addButton(withTitle: NSLocalizedString("Remember pairing", comment: "pair phone NSAlert"))
        alert.addButton(withTitle: NSLocalizedString("Don't remember", comment: "pair phone NSAlert"))
        alert.showsSuppressionButton = true // TODO doesn't work
        alert.runModal()

    }

}
