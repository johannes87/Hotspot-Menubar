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
///
/// We hard wire to Gregorian calendar because that's the only supported and tested calendar where this is used.
extension Date {
    var yearNumber: Int {
        return Calendar(identifier: .gregorian).component(.year, from: self)
    }

    var monthNumber: Int {
        return Calendar(identifier: .gregorian).component(.month, from: self)
    }

    var dayNumber: Int {
        return Calendar(identifier: .gregorian).component(.day, from: self)
    }

    /// Used to get a dictionary key from a Date that contains the year and month components
    var yearMonthKey: YearMonthKey {
            return "\(self.yearNumber)-\(self.monthNumber)"
    }

    var daysInMonth: Int {
        let interval = Calendar(identifier: .gregorian).dateInterval(of: .month, for: self)!
        let days = Calendar(identifier: .gregorian).dateComponents([.day], from: interval.start, to: interval.end).day!
        return days
    }

    static func fromYearAndMonth(year: Int, month: Int) -> Date? {
        // Pinning the hour is important because otherwise it might happen to land on a date
        // that does not exist. See: https://developer.apple.com/forums/thread/685878?answerId=690199022#690199022
        let components = DateComponents(year: year, month: month, day: 1, hour: 12)
        return Calendar(identifier: .gregorian).date(from: components)
    }
}
