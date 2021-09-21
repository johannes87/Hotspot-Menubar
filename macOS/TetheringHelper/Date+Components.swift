//
//  Date+Components.swift
//  TetheringHelper
//
//  Created by Johannes Bittner on 28.07.21.
//  Copyright © 2021 Johannes Bittner. All rights reserved.
//

import Foundation

/// Easily access the year and month components from a Date
extension Date {
    /// Access yearnumber component from Date
    var yearNumber: Int {
        return Calendar.current.component(.year, from: self)
    }

    /// Access month number component form a Date
    var monthNumber: Int {
        return Calendar.current.component(.month, from: self)
    }
}
