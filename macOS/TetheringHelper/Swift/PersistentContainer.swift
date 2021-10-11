//
//  PersistentContainer.swift
//  TetheringHelper
//
//  Created by Johannes Bittner on 11.10.21.
//

import Foundation
import CoreData

class PersistentContainer: NSPersistentContainer {
    static let modelName = "DataModel"

    /// Use `shared` to use the PersistentContainer instance
    static let shared: PersistentContainer = {
        let container = PersistentContainer(name: modelName)
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Unable to load persistent stores, please report a bug: \(error)")
            }
        }
        return container
    }()

    func createNewTetheringSession(withPhoneName phoneName: String) -> TetheringSession {
        let session = TetheringSession(context: viewContext)
        session.created = Date()
        session.bytesTransferred = 0
        session.phoneName = phoneName
        viewContext.insert(session)
        return session
    }

    /// getTetheringSessions retrieves all TetheringSession objects, sorted descending by creation date
    func getTetheringSessions() -> [TetheringSession] {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(
            entityName: String(describing: TetheringSession.self))
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "created", ascending: false)]

        do {
            let fetechedTetheringSessions = try viewContext
                .fetch(fetchRequest) as! [TetheringSession]

            return fetechedTetheringSessions
        } catch {
            fatalError("Error fetching sessions in PersistentContainer, please report a bug: \(error)")
        }
    }

    /// Convenience function that handles exception when saving
    func save() {
        do {
            try viewContext.save()
        } catch {
            fatalError("Error saving viewContext in PersistentContainer, please report a bug: \(error)")
        }
    }
}
