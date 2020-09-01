//
//  DataStatistics.swift
//  TetheringHelper
//
//  Created by Johannes Bittner on 29.11.19.
//  Copyright © 2019 Johannes Bittner. All rights reserved.
//

import Foundation
import CoreData

class DataStorage {
    private lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "DataModel")
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Unable to load persistent stores: \(error)")
            }
        }
        return container
    }()

    func createNewTetheringSession() {
        

    }
    func getTetheringSessions() { }
    func getCurrentTetheringSession() { }

    func foo() {
        // store object

        let foo = TetheringSession(context: persistentContainer.viewContext)
        print("foo1 \(foo)")

        foo.bytesTransferred = 4323
        foo.created = Date()
        persistentContainer.viewContext.insert(foo)
        do {
            try persistentContainer.viewContext.save()
        } catch {
            fatalError("save error: \(error)")
        }

    }

    func bar() {
        // fetch objects

        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(
            entityName: String(describing: TetheringSession.self))
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "created", ascending: false)]

        do {
            let fetechedTetheringSessions = try persistentContainer
                .viewContext
                .fetch(fetchRequest) as! [TetheringSession]

            fetechedTetheringSessions.forEach { tetheringSession in
                print("created=\(String(describing: tetheringSession.created!)), bytesTransferred=\(tetheringSession.bytesTransferred)")
            }
        } catch {
            fatalError("fetch error: \(error)")
        }

    }
    
}
