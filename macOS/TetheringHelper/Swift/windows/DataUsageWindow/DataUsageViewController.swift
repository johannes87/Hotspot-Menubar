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
    @IBOutlet weak var prevMonthButton: NSButton!
    @IBOutlet weak var nextMonthButton: NSButton!
    
    private var firstSessionCreated: Date?
    private var lastSessionCreated: Date?

    /// Aggregated data usage, the dictionary values are ready for being passed to DataUsageVisualization
    /// It's also used to check if a data for a given month (YearMonthKey) exists
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

    private func selectNextOrPreviousMonth(searchDirection: MonthSearchDirection) {
        guard let newMonth = findExistingMonth(searchDirection: searchDirection) else { return }
        
        currentDate = newMonth

        // Year might have changed
        populateMonthPopupButton()

        selectCurrentDateInDateButtons()
        visualizeDataUsageOfCurrentDate()
    }

    /// Finds an month that has TetheringSession objects
    ///
    /// - Parameter searchDirection: in which direction the search should be performed
    /// - Returns: A `Date` object with the next or previous month, or `nil` if none was found.
    private func findExistingMonth(searchDirection: MonthSearchDirection) -> Date? {
        var selectedMonthIsInBounds: () -> Bool
        var searchDirectionSummand: Int
    
        var selectedMonth = self.currentDate

        if searchDirection == .next {
            selectedMonthIsInBounds = { selectedMonth <= self.lastSessionCreated! }
            searchDirectionSummand = 1
        } else { // .previous
            selectedMonthIsInBounds = { selectedMonth >= self.firstSessionCreated! }
            searchDirectionSummand = -1
        }

        var monthFound = false

        while !monthFound && selectedMonthIsInBounds() {
            selectedMonth = Calendar.init(identifier: .gregorian).date(
                byAdding: DateComponents(month: searchDirectionSummand),
                to: selectedMonth)!
            if dataUsageByMonthAndDay[selectedMonth.yearMonthKey] != nil {
                monthFound = true
            }
        }
        selectedMonth = selectedMonth.clamp(from: firstSessionCreated!, until: lastSessionCreated!)
        
        return monthFound ? selectedMonth : nil
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

        showMonthlyDataUsage(monthlyBytesUsage: monthlyBytesUsage)
        showDateInTitle()
        updatePreviousAndNextMonthButtonEnabledState()
    }
    
    private func showMonthlyDataUsage(monthlyBytesUsage: Int64) {
        let monthlyDataUsageTextTemplate = NSLocalizedString(
            "%@ used in",
            comment: "text for monthly data usage in data usage window next to date selection (less than or equal 1 gigabyte)"
        )
        let monthlyDataUsageText = String(format: monthlyDataUsageTextTemplate,
                                          Utils.byteCountFormatter.string(fromByteCount: monthlyBytesUsage))
        monthlyDataUsageTextField.stringValue = monthlyDataUsageText
    }
    
    private func showDateInTitle() {
        let monthYearFormatter = DateFormatter()
        monthYearFormatter.calendar = Calendar.init(identifier: .gregorian)
        monthYearFormatter.setLocalizedDateFormatFromTemplate("MMMMyyyy")
        
        let windowTitleTemplate = NSLocalizedString(
            "Data usage on %@",
            comment: "window title for data usage window, e.g. 'Data usage on September 2021'")

        view.window?.title = String(format: windowTitleTemplate, monthYearFormatter.string(from: currentDate))
    }
    
    private func updatePreviousAndNextMonthButtonEnabledState() {
        let prevMonth = findExistingMonth(searchDirection: .previous)
        let nextMonth = findExistingMonth(searchDirection: .next)
        
        prevMonthButton.isEnabled = prevMonth != nil
        nextMonthButton.isEnabled = nextMonth != nil
    }
    
    private func aggregateDataUsageByMonthAndDay(tetheringSessions: [TetheringSession]) {
        // this function is going to be called again
        dataUsageByMonthAndDay = [:]
        
        let sessionsGroupedByDay = Dictionary(grouping: tetheringSessions) {
            "\($0.created!.yearMonthKey)-\($0.created!.dayNumber)"
        }
        
        sessionsGroupedByDay.forEach { _, daySessions in
            let dailyDataUsage = daySessions.reduce(0) { $0 + $1.bytesTransferred }
            let firstSessionOfDay = daySessions.first!
            
            if dataUsageByMonthAndDay[firstSessionOfDay.created!.yearMonthKey] == nil {
                dataUsageByMonthAndDay[firstSessionOfDay.created!.yearMonthKey] = [DataUsage](
                    repeating: DataUsage(bytesTransferred: 0, date: nil),
                    count: firstSessionOfDay.created!.daysInMonth)
            }
            
            let dayIndex = firstSessionOfDay.created!.dayNumber - 1
            dataUsageByMonthAndDay[firstSessionOfDay.created!.yearMonthKey]![dayIndex] = DataUsage(
                bytesTransferred: dailyDataUsage,
                date: firstSessionOfDay.created)
        }
    }
}
