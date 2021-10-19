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

struct DataUsage: Comparable {
    static func < (lhs: DataUsage, rhs: DataUsage) -> Bool {
        return lhs.bytesTransferred < rhs.bytesTransferred
    }

    var bytesTransferred: Int64
    var date: Date?
}

class DataUsageViewController: NSViewController {
    @IBOutlet weak var dataUsageVisualization: DataUsageVisualization!
    @IBOutlet weak var monthPopUpButton: NSPopUpButton!
    @IBOutlet weak var yearPopUpButton: NSPopUpButton!
    @IBOutlet weak var monthlyDataUsageTextField: NSTextField!
    
    private var firstSessionCreated: Date?
    private var lastSessionCreated: Date?

    /// Aggregated data usage, the dictionary values are ready for being passed to DataUsageVisualization
    /// It's also used to check if a data for a given YearMonthKey exists
    private var dataUsageByMonthAndDay: [YearMonthKey: [DataUsage]] = [:]

    /// Converts long names of months (e.g. "September") to numbers, and extracts names from `Date` objects.
    private let monthFormatter = DateFormatter()

    /// The date that is being visualized. Only the year and month components of the date are used
    private var currentDate = Date()
    
    private var sessionChangeObserver: Any?

    override func viewDidLoad() {
        super.viewDidLoad()

        monthFormatter.dateFormat = "LLLL"
        monthFormatter.calendar = Calendar.init(identifier: .gregorian)

        processSessions()

        populateYearPopupButton()
        populateMonthPopupButton()
        selectCurrentDateInDateButtons()
    }

    override func viewDidAppear() {
        observeSessionChanges()
        visualizeDataUsageOfCurrentDate()
    }
    
    override func viewDidDisappear() {
        removeSessionChangeObserver()
    }

    @IBAction func monthPopUpButtonChanged(_ sender: Any) {
        let nameOfSelectedMonth = monthPopUpButton.titleOfSelectedItem!
        let monthNumberOfSelectedMonth = monthFormatter.date(from: nameOfSelectedMonth)!.monthNumber

        currentDate = Date.fromYearAndMonth(
            year: currentDate.yearNumber,
            month: monthNumberOfSelectedMonth
        )!

        visualizeDataUsageOfCurrentDate()
    }

    @IBAction func yearPopUpButtonChanged(_ sender: Any) {
        let selectedYear = Int(yearPopUpButton.titleOfSelectedItem!)!

        currentDate = Date
            .fromYearAndMonth(year: selectedYear, month: currentDate.monthNumber)!
            .clamp(from: firstSessionCreated!, until: lastSessionCreated!)
        
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
            currentDate = Calendar.init(identifier: .gregorian).date(byAdding: DateComponents(month: currentDateSummand), to: currentDate)!
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
        let standaloneMonthSymbols = monthFormatter.standaloneMonthSymbols!

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
            monthlyBytesUsage = monthUsage
                .map { $0.bytesTransferred }
                .reduce(0, { dayA, dayB in dayA + dayB })
        } else {
            dataUsageVisualization.dataUsage = nil
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
                                                           monthlyMegaBytesUsage / 1024)
        }

        let monthYearFormatter = DateFormatter()
        monthYearFormatter.calendar = Calendar.init(identifier: .gregorian)
        monthYearFormatter.setLocalizedDateFormatFromTemplate("MMMMyyyy")

        let windowTitle = NSLocalizedString(
            "Data usage on %@",
            comment: "window title for data usage window, e.g. 'Data usage on September 2021'")

        view.window?.title = String(format: windowTitle, monthYearFormatter.string(from: currentDate))
    }

    private func aggregateDataUsageByMonthAndDay(tetheringSessions: [TetheringSession]) {
        var dailyBytesTransferred: Int64 = 0
        var prevDay: Int?
        var prevYearMonthKey: YearMonthKey?
        var prevSession: TetheringSession?
        
        // reset because it's going to be called again
        dataUsageByMonthAndDay = [:]

        // The aggregation assumes tetheringSessions is sorted
        tetheringSessions.forEach { session in
            let yearMonthKey = session.created!.yearMonthKey
            let day = session.created!.dayNumber

            let dayChanged = prevDay != nil && (day != prevDay || yearMonthKey != prevYearMonthKey)
            let isLastSession = session == tetheringSessions.last

            if dayChanged || isLastSession {
                if dataUsageByMonthAndDay[prevYearMonthKey!] == nil {
                    dataUsageByMonthAndDay[prevYearMonthKey!] = [DataUsage](
                        repeating: DataUsage(bytesTransferred: 0, date: nil),
                        count: prevSession!.created!.daysInMonth)
                }
                dataUsageByMonthAndDay[prevYearMonthKey!]![prevDay! - 1].bytesTransferred = dailyBytesTransferred
                dataUsageByMonthAndDay[prevYearMonthKey!]![prevDay! - 1].date = prevSession?.created
                dailyBytesTransferred = 0
            }

            dailyBytesTransferred += session.bytesTransferred

            prevDay = day
            prevYearMonthKey = yearMonthKey
            prevSession = session
        }
    }
    
    private func processSessions() {
        let tetheringSessions = PersistentContainer.shared.getTetheringSessions()

        firstSessionCreated = tetheringSessions.last?.created
        lastSessionCreated = tetheringSessions.first?.created

        currentDate = lastSessionCreated!

        aggregateDataUsageByMonthAndDay(tetheringSessions: tetheringSessions)
    }
    
    private func observeSessionChanges() {
        sessionChangeObserver = PersistentContainer.observeSessionChanges { [weak self] session in
            self?.processSessions()
            self?.visualizeDataUsageOfCurrentDate()
        }
    }
    
    private func removeSessionChangeObserver() {
        if let observer = sessionChangeObserver {
            NotificationCenter.default.removeObserver(observer)
            sessionChangeObserver = nil
        }
    }
}
