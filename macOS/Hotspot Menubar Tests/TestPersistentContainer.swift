//
//  TestPersistentContainer.swift
//  Hotspot Menubar
//
//  Created by Johannes Bittner on 11.10.21.
//

import Foundation
import CoreData

/// Intended to be used by replacing "PersistentContainer.shared" in the codebase with one of the statically defined TestPersistentContainers
class TestPersistentContainer: PersistentContainer {
    /// An empty in-memory container containing no sessions
    static let emptyInMemoryShared: TestPersistentContainer = {
        let persistentStoreDescription = NSPersistentStoreDescription()
        persistentStoreDescription.type = NSInMemoryStoreType

        let container = TestPersistentContainer(name: modelName)
        container.persistentStoreDescriptions = [persistentStoreDescription]

        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }

        return container
    }()

    /// A container containing test sessions for a few years
    static let testSessionsShared: TestPersistentContainer = {
        let container = emptyInMemoryShared
        container.createTestSessions()
        return container
    }()

    private func createTestSessions() {
        // Configuration
        let phoneName = "TestSessionStoragePhone"
        let sessionsPerDay = 3
        let numberOfGeneratedYears = 4
        let firstYearStartMonth = 4

        let currentDate = Date()
        let calendar = Calendar.init(identifier: .gregorian)
        let currentYear = calendar.component(.year, from: currentDate)
        let currentMonth = calendar.component(.month, from: currentDate)
        let currentDay = calendar.component(.day, from: currentDate)

        let firstYear = currentYear - numberOfGeneratedYears + 1
        for year in firstYear...currentYear {
            var maxMonth = 12
            if (year == currentYear) {
                maxMonth = currentMonth
            }

            var startMonth = 1
            // The first year shouldn't start on january to cover edge case
            if year == firstYear {
                startMonth = firstYearStartMonth
            }

            for month in startMonth...maxMonth {
                // Leave some gap to cover edge case
                if year != firstYear && year != currentYear && month == 3 {
                    continue
                }

                let daysInMonth = calendar.range(
                    of: .day,
                    in: .month,
                    for: calendar.date(from: DateComponents(year: year, month: month))!)!.count

                var maxDay = daysInMonth
                if (year == currentYear && month == currentMonth) {
                    maxDay = currentDay
                }

                for day in 1...maxDay {
                    for sessionNumber in 1...sessionsPerDay {
                        let session = createNewTetheringSession(withPhoneName: phoneName)

                        // use sessionNumber for hour value. Assuming sessionsPerDay < 24 here
                        let dateComponents = DateComponents(year: year, month: month, day: day, hour: sessionNumber)
                        session.created = calendar.date(from: dateComponents)

                        let megaByte: Int64 = 1024*1024
                        session.bytesTransferred = Int64.random(in: 3 * megaByte...300 * megaByte)

                        print("Created test session with created=\(String(describing: session.created!)), bytesTransferred=\(session.bytesTransferred)")
                    }
                }
            }
        }
    }
}
