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
    
    /// Observes when a TetheringSession is changed by CoreData
    ///
    /// - Parameter onChange:the block that executes when the a session changes
    /// - Returns: The object returned by `NotificationCenter.addObserver`. You are responsible for removing the observation using this object.
    static func observeSessionChanges(onChange: @escaping (TetheringSession) -> ()) -> Any {
        return NotificationCenter.default.addObserver(
            forName: .NSManagedObjectContextObjectsDidChange,
            object: nil,
            queue: nil) { notification in
                let insertedSession = (notification.userInfo?[NSInsertedObjectsKey] as? Set<TetheringSession>)?.first
                let updatedSession = (notification.userInfo?[NSUpdatedObjectsKey] as? Set<TetheringSession>)?.first
                
                if insertedSession != nil {
                    onChange(insertedSession!)
                } else if updatedSession != nil {
                    onChange(updatedSession!)
                } else {
                    return
                }
        }
    }

    func createNewTetheringSession(withPhoneName phoneName: String) -> TetheringSession {
        var newSession: TetheringSession!
        
        viewContext.performAndWait {
            newSession = TetheringSession(context: viewContext)
            newSession.created = Date()
            newSession.bytesTransferred = 0
            newSession.phoneName = phoneName
            viewContext.insert(newSession)
            save()
        }
        
        return newSession
    }
    
    func updateTetheringSession(_ session: TetheringSession, withBytesTransferred bytesTransferred: Int64) {
        viewContext.performAndWait {
            session.bytesTransferred = bytesTransferred
            save()
        }
    }

    /// getTetheringSessions retrieves all TetheringSession objects, sorted descending by creation date
    func getTetheringSessions() -> [TetheringSession] {
        var fetchedTetheringSessions: [TetheringSession] = []
        
        viewContext.performAndWait {
            do {
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(
                    entityName: String(describing: TetheringSession.self))
                fetchRequest.sortDescriptors = [NSSortDescriptor(key: "created", ascending: false)]
                
                fetchedTetheringSessions = try viewContext.fetch(fetchRequest) as! [TetheringSession]
            } catch {
                fatalError("Error fetching sessions in PersistentContainer, please report a bug: \(error)")
            }
        }
        
        return fetchedTetheringSessions
    }

    /// Convenience function that handles exception when saving
    private func save() {
        viewContext.performAndWait {
            do {
                try viewContext.save()
            } catch {
                fatalError("Error saving viewContext in PersistentContainer, please report a bug: \(error)")
            }
        }
    }
}
