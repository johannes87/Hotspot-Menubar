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

class AndroidConnector: NSObject, NetServiceBrowserDelegate {
    private let netServiceBrowser = NetServiceBrowser()

    private(set) var signalQuality = SignalQuality.no_signal
    private(set) var signalType = SignalType.no_signal

    private var tetheringHelperService: NetService?


    public func getSignal() {
        if tetheringHelperService != nil {

//            let json = getJSONFromAndroid()
//            let json = JSONSerialization.jsonObject(with: data, options: [])
            

        }

        // TODO: fetch data from android here
        signalQuality = SignalQuality.allCases.randomElement()!
        signalType = SignalType.allCases.randomElement()!
    }




    private func createNSAlertFooTODO() {
        // TODO: consider not showing any alert, just the icon change when successfully paired
        let alert = NSAlert()
        // TODO: add "Pairing successful!"
        alert.messageText = NSLocalizedString("Would you like to remember this pairing?",
                                              comment: "pair phone NSAlert")
        alert.informativeText = NSLocalizedString("When you choose to remember the pairing, TetheringHelper will automatically connect to the phone when it is available. You can later reset your choices in the preferences.",
                                                  comment: "pair phone NSAlert")
        alert.alertStyle = .informational
        alert.addButton(withTitle: NSLocalizedString("Remember pairing", comment: "pair phone NSAlert"))
        alert.addButton(withTitle: NSLocalizedString("Don't remember", comment: "pair phone NSAlert"))
        alert.showsSuppressionButton = true // TODO: make suppression button work
        alert.runModal()

    }


    @IBAction public func pair(sender: Any) {
        print("connector pair!")


        tetheringHelperService = nil
        netServiceBrowser.delegate = self
        // stop before searching, because searchForServices otherwise works only once (subsequent searches
        // return activityInProgress error)
        netServiceBrowser.stop()
        netServiceBrowser.searchForServices(ofType: "_tetheringhelper._tcp.", inDomain: "")

        // TODO: show progress icon in status item during pairing

        // show user a message if service couldn't be found
        DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: {
            self.netServiceBrowser.stop()
            if self.tetheringHelperService == nil {
                let alert = NSAlert()
                alert.messageText = NSLocalizedString("No phone could be found for pairing",
                                                      comment: "user clicks 'pair' and phone couldn't be found: NSAlert messageText")
                alert.informativeText = NSLocalizedString("Make sure you're tethered to your Android phone and the TetheringHelper app is running on Android.",
                                                          comment: "explanation what to do when no phone to pair was found")
                alert.runModal()
            }
        })
    }

    // MARK: Service discovery

    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        print("Discovered the service")
        print("- name:", service.name)
        print("- type", service.type)
        print("- domain:", service.domain)

        tetheringHelperService = service
    }

    func netServiceBrowserDidStopSearch(_ browser: NetServiceBrowser) {
        // TODO: consider removing
        print("Search stopped")
        // https://stackoverflow.com/questions/42717027/ios-bonjour-swift-3-search-never-stops

    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String : NSNumber]) {
        // TODO: consider removing
        print("netServiceBrowser didNotSearch")
        let errorCode = errorDict[NetService.errorCode]!.intValue
        let error = NetService.ErrorCode.init(rawValue: errorCode)

        print("NetService Error code is:")
        switch error {
        case .activityInProgress:
            print("activityInProgress")
        case .badArgumentError:
            print("badArgumentError")
        case .cancelledError:
            print("cancelledError")
        case .collisionError:
            print("collisionError")
        case .notFoundError:
            print("notFoundError")
        case .none:
            print("none")
        case .some(.unknownError):
            print("some(.unknownError")
        case .some(.invalidError):
            print("some(.invalidError)")
        case .some(.timeoutError):
            print("some(.timeoutError")
        case .some(_):
            print("some(_)")
        }
    }

}
