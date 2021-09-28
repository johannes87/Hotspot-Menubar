//
//  SessionStorage.swift
//  TetheringHelper
//
//  Created by Johannes Bittner on 29.11.19.
//  Copyright © 2019 Johannes Bittner. All rights reserved.
//

import Foundation
import CoreData

/// SessionStorage's responsibility is to persistently store and retrieve TetheringSession objects
/// It uses CoreData for this, and abstracts away the interfaces to CoreData
class SessionStorage {
    let modelName = "DataModel"

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: modelName)
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Unable to load persistent stores: \(error)")
            }
        }
        return container
    }()

    func createNewTetheringSession(withPhoneName phoneName: String) -> TetheringSession {
        let session = TetheringSession(context: persistentContainer.viewContext)
        session.created = Date()
        session.bytesTransferred = 0
        session.phoneName = phoneName
        persistentContainer.viewContext.insert(session)
        return session
    }

    /// getTetheringSessions retrieves all TetheringSession objects, sorted descending by creation date
    func getTetheringSessions() -> [TetheringSession] {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(
            entityName: String(describing: TetheringSession.self))
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "created", ascending: false)]

        do {
            let fetechedTetheringSessions = try persistentContainer
                .viewContext
                .fetch(fetchRequest) as! [TetheringSession]

            return fetechedTetheringSessions
        } catch {
            fatalError("Error fetching sessions: \(error)")
        }
    }

    /// Save modifications to persistent store.
    ///
    /// It is public so that external code can change a TetheringSession object, and save() the changes
    func save() {
        do {
            try persistentContainer.viewContext.save()
        } catch {
            fatalError("Error saving viewContext: \(error)")
        }
    }

}
