//
//  DatabaseClient+FetchRequest.swift
//  Hang
//
//  Created by Martin Troup on 14.05.2021.
//

import CoreData

// MARK: - FetchRequest extensions

extension DatabaseClient {
    // NOTE: Cannot extend NSFetchRequest (Objective-C) since generic functions cannot be exposed to @objc runtime.
    struct FetchRequest {
        static func entity<DatabaseModel: NSManagedObject>() -> NSFetchRequest<DatabaseModel> {
            NSFetchRequest(entityName: DatabaseModel.entityName)
        }

        static func single<DatabaseModel: NSManagedObject>(
            withID modelID: AnyHashable
        ) -> (NSFetchRequest<DatabaseModel>) -> NSFetchRequest<DatabaseModel> {
            { request in
                let predicate = NSPredicate(format: "%K == %@", "id", modelID as CVarArg)
                request.predicate = predicate

                return request
            }
        }

        static func sorted<DatabaseModel: NSManagedObject>(
            by sortDescriptors: [NSSortDescriptor] = []
        ) -> (NSFetchRequest<DatabaseModel>) -> NSFetchRequest<DatabaseModel> {
            { request in
                request.sortDescriptors = sortDescriptors

                return request
            }
        }
    }
}
