//
//  main.swift
//  TestBonjourService
//
//  Created by Johannes Bittner on 14.07.20.
//  Copyright © 2020 Johannes Bittner. All rights reserved.
//

import Foundation
import Network

func getJSONResponse() -> Data {
    let jsonObject: [String: Any] = [
        "quality": [0,1,2,3,4].randomElement()!,
        "type": ["2G", "E", "3G", "H", "LTE", "5G"].randomElement()!
    ]
    return try! JSONSerialization.data(withJSONObject: jsonObject)
}

let service = NetService(
    domain: "",
    type: "_tetheringhelper._tcp.",
    name: "MyVirtualPhone",
    port: 31337)

let port = NWEndpoint.Port(integerLiteral:
    NWEndpoint.Port.IntegerLiteralType(service.port))
let listener = try! NWListener(using: .tcp, on: port)


listener.newConnectionHandler = { nwConnection in
    print("\(NSDate()): new connection")
    nwConnection.start(queue: .main)

    let data = getJSONResponse()
    nwConnection.send(content: data, completion: .contentProcessed({ error in
        if let error = error {
            fatalError("error in nwConnection.send: \(error)")
        }
        nwConnection.cancel()
    }))

}

listener.start(queue: .main)
service.publish()
dispatchMain()
