//
//  Date+Components.swift
//  TetheringHelper
//
//  Created by Johannes Bittner on 28.07.21.
//  Copyright © 2021 Johannes Bittner. All rights reserved.
//

import Foundation

typealias YearMonthKey = String

/// Easily access the useful components, like year and month, from a Date
extension Date {
    var yearNumber: Int {
        return Calendar.current.component(.year, from: self)
    }

    var monthNumber: Int {
        return Calendar.current.component(.month, from: self)
    }

    var dayNumber: Int {
        return Calendar.current.component(.day, from: self)
    }

    /// Used to get a dictionary key from a Date that contains the year and month components
    var yearMonthKey: YearMonthKey {
            return "\(self.yearNumber)-\(self.monthNumber)"
    }

    var daysInMonth: Int {
        let interval = Calendar.current.dateInterval(of: .month, for: self)!
        let days = Calendar.current.dateComponents([.day], from: interval.start, to: interval.end).day!
        return days
    }
}
