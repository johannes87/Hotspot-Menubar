//
//  DataUsageViewController.swift
//  TetheringHelper
//
//  Created by Johannes Bittner on 29.06.21.
//  Copyright © 2021 Johannes Bittner. All rights reserved.
//

import Cocoa

enum MonthSearchDirection {
    case next
    case previous
}

// TODO: test with other locales
class DataUsageViewController: NSViewController {
    @IBOutlet weak var dataUsageVisualization: DataUsageVisualization!
    @IBOutlet weak var monthPopUpButton: NSPopUpButton!
    @IBOutlet weak var yearPopUpButton: NSPopUpButton!
    @IBOutlet weak var monthlyDataUsageTextField: NSTextField!
    
    private var firstSessionCreated: Date? = nil
    private var lastSessionCreated: Date? = nil

    /// Aggregated data usage, the dictionary values are ready for being passed to DataUsageVisualization
    /// It's also used to check if a data for a given YearMonthKey exists
    private var dataUsageByMonthAndDay: [YearMonthKey: [Int64]] = [:]

    /// Converts long names of months (e.g. "September") to numbers, and extracts names from `Date` objects.
    private let monthFormatter = DateFormatter()

    /// The date that is being visualized. Only the year and month components of the date are used
    private var currentDate = Date()

    override func viewDidLoad() {
        super.viewDidLoad()

        monthFormatter.dateFormat = "LLLL"

        let sessionStorage = SessionStorage()
        let tetheringSessions = sessionStorage.getTetheringSessions()

        firstSessionCreated = tetheringSessions.last?.created
        lastSessionCreated = tetheringSessions.first?.created

        currentDate = lastSessionCreated!

        aggregateDataUsageByMonthAndDay(tetheringSessions: tetheringSessions)

        populateYearPopupButton()
        populateMonthPopupButton()
        selectCurrentDateInDateButtons()
        visualizeDataUsageOfCurrentDate()
    }

    @IBAction func monthPopUpButtonChanged(_ sender: Any) {
        let nameOfSelectedMonth = monthPopUpButton.titleOfSelectedItem!
        let monthNumberOfSelectedMonth = monthFormatter.date(from: nameOfSelectedMonth)?.monthNumber

        let componentsOfCurrentDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: currentDate)
        var componentsOfNewDate = componentsOfCurrentDate
        componentsOfNewDate.month = monthNumberOfSelectedMonth
        currentDate = Calendar.current.date(from: componentsOfNewDate)!

        visualizeDataUsageOfCurrentDate()
    }

    @IBAction func yearPopUpButtonChanged(_ sender: Any) {
        let selectedYear = Int(yearPopUpButton.titleOfSelectedItem!)!

        let componentsOfCurrentDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: currentDate)
        var componentsOfNewDate = componentsOfCurrentDate
        componentsOfNewDate.year = selectedYear
        let newDate = Calendar.current.date(from: componentsOfNewDate)!
            .clamp(from: firstSessionCreated!, until: lastSessionCreated!)
        currentDate = newDate
        
        // Month button contents depends on the selected year
        populateMonthPopupButton()

        // After populating the selection is reset
        selectCurrentDateInDateButtons()

        visualizeDataUsageOfCurrentDate()
    }

    @IBAction func nextMonthButtonClicked(_ sender: Any) {
        selectNextOrPreviousMonth(searchDirection: .next)
    }

    @IBAction func prevMonthButtonClicked(_ sender: Any) {
        selectNextOrPreviousMonth(searchDirection: .previous)
    }

    private func selectNextOrPreviousMonth(searchDirection: MonthSearchDirection) {
        var currentDateIsInBounds: () -> Bool
        var currentDateSummand: Int

        if searchDirection == .next {
            currentDateIsInBounds = { self.currentDate <= self.lastSessionCreated! }
            currentDateSummand = 1
        } else { // .previous
            currentDateIsInBounds = { self.currentDate >= self.firstSessionCreated! }
            currentDateSummand = -1
        }

        var monthFound = false

        while !monthFound && currentDateIsInBounds() {
            currentDate = Calendar.current.date(byAdding: DateComponents(month: currentDateSummand), to: currentDate)!
            if dataUsageByMonthAndDay[currentDate.yearMonthKey] != nil {
                monthFound = true
            }
        }
        currentDate = currentDate.clamp(from: firstSessionCreated!, until: lastSessionCreated!)

        // Year might have changed
        populateMonthPopupButton()

        selectCurrentDateInDateButtons()
        visualizeDataUsageOfCurrentDate()
    }

    /// Populate the "month" popup button based on the current year.
    private func populateMonthPopupButton() {
        let standaloneMonthSymbols = DateFormatter().standaloneMonthSymbols!

        let monthsWithData = (1...12)
            .filter { monthNumber in dataUsageByMonthAndDay["\(currentDate.yearNumber)-\(monthNumber)"] != nil }
            .map { monthNumber in standaloneMonthSymbols[monthNumber - 1] }

        monthPopUpButton.removeAllItems()
        monthPopUpButton.addItems(withTitles: monthsWithData)
    }

    private func populateYearPopupButton() {
        let yearsToAdd = (firstSessionCreated!.yearNumber...lastSessionCreated!.yearNumber)
            .map { year in String(year) }
        yearPopUpButton.removeAllItems()
        yearPopUpButton.addItems(withTitles: yearsToAdd)
    }

    private func selectCurrentDateInDateButtons() {
        let nameOfMonth = monthFormatter.string(from: currentDate)
        let year = String(currentDate.yearNumber)

        monthPopUpButton.selectItem(withTitle: nameOfMonth)
        yearPopUpButton.selectItem(withTitle: year)
    }

    private func visualizeDataUsageOfCurrentDate() {
        var monthlyBytesUsage: Int64 = 0
        if let monthUsage = dataUsageByMonthAndDay[currentDate.yearMonthKey] {
            dataUsageVisualization.dataUsage = monthUsage
            monthlyBytesUsage = monthUsage.reduce(0, { dayA, dayB in dayA + dayB})
        } else {
            dataUsageVisualization.dataUsage = [Int64](repeating: 0, count: currentDate.daysInMonth)
        }

        let monthlyDataUsageTextMB = NSLocalizedString(
            "%.2f MB used in",
            comment: "text for monthly data usage in data usage window next to date selection (less than or equal 1 gigabyte)"
        )
        let monthlyDataUsageTextGB = NSLocalizedString(
            "%.2f GB used in",
            comment: "text for monthly data usage in data usage window next to date selection (more than 1 gigabyte)"
        )

        let monthlyMegaBytesUsage = Double(monthlyBytesUsage) / 1024 / 1024

        if monthlyMegaBytesUsage <= 1024 {
            monthlyDataUsageTextField.stringValue = String(format: monthlyDataUsageTextMB,
                                                           monthlyMegaBytesUsage)
        } else {
            monthlyDataUsageTextField.stringValue = String(format: monthlyDataUsageTextGB,
                                                           monthlyMegaBytesUsage / 1024
            )
        }
    }

    private func aggregateDataUsageByMonthAndDay(tetheringSessions: [TetheringSession]) {
        var dailyBytesTransferred: Int64 = 0
        var prevDay: Int?
        var prevYearMonthKey: String?
        var prevSession: TetheringSession?

        // The aggregation assumes tetheringSessions is sorted
        tetheringSessions.forEach { session in
            let yearMonthKey = session.created!.yearMonthKey
            let day = session.created!.dayNumber

            let dayChanged = prevDay != nil && (day != prevDay || yearMonthKey != prevYearMonthKey)
            let isLastSession = session == tetheringSessions.last

            if dayChanged || isLastSession {
                if dataUsageByMonthAndDay[prevYearMonthKey!] == nil {
                    dataUsageByMonthAndDay[prevYearMonthKey!] = [Int64](repeating: 0, count: prevSession!.created!.daysInMonth)
                }
                dataUsageByMonthAndDay[prevYearMonthKey!]![prevDay! - 1] = dailyBytesTransferred
                dailyBytesTransferred = 0
            }

            dailyBytesTransferred += session.bytesTransferred

            prevDay = day
            prevYearMonthKey = yearMonthKey
            prevSession = session
        }
    }
}
