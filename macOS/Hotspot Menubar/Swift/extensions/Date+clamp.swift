//
//  Date+Clamp.swift
//  TetheringHelper
//
//  Created by Johannes Bittner on 03.08.21.
//  Copyright © 2021 Johannes Bittner. All rights reserved.
//

import Foundation


extension Date {
    /// Makes sure date is between "from" and "until"
    func clamp(from: Date, until: Date) -> Date {
        return min(max(from, self), until)
    }
}
