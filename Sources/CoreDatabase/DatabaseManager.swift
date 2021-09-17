//
//  DatabaseManager.swift
//  Hang
//
//  Created by Martin Troup on 11.05.2021.
//

import CoreData

// MARK: - Database

class Database {
    enum DatabaseType {
        case persistant(url: URL)
        case inMemory
    }

    let databaseType: DatabaseType
    let containerName: String

    var databaseContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    init(databaseType: DatabaseType, containerName: String) {
        self.databaseType = databaseType
        self.containerName = containerName
    }

    // MARK: - Database objects

    lazy var persistentContainer: NSPersistentContainer = {
        let container = self.newPersistentContainer

        switch self.databaseType {
        case .inMemory:
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [description]
        case .persistant(let url):
            let description = NSPersistentStoreDescription(url: url)
            container.persistentStoreDescriptions = [description]
        }

        loadStores(for: container)

        return container
    }()

    var newPersistentContainer: NSPersistentContainer {
        NSPersistentContainer(name: containerName)
    }

    func loadStores(for container: NSPersistentContainer) {
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Unable to load persistent stores with error: \(error).")
            }
        }
    }
}

// MARK: - DatabaseProvider

public struct DatabaseProvider {
    let database: Database

    public var context: NSManagedObjectContext {
        database.databaseContext
    }
}

public extension DatabaseProvider {
    static func live(onURL url: URL, containerName: String) -> Self {
        .init(database: .init(databaseType: .persistant(url: url), containerName: containerName))
    }

    static func mock(containerName: String) -> Self {
        .init(database: .init(databaseType: .inMemory, containerName: containerName))
    }
}
