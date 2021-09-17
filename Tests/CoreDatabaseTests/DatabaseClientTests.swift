//
//  DatabaseClientTests.swift
//  HangTests
//
//  Created by Martin Troup on 16.05.2021.
//

import Combine
import CoreData
@testable import CoreDatabase
import XCTest


class DatabaseClientTests: XCTestCase {

    private let databaseContainerName = "DatabaseTestModel"
    var context: NSManagedObjectContext!
    var testModelRepository: DatabaseRepository<TestModel, DomainTestModel>!
    var subscriptions = Set<AnyCancellable>()

    override func setUp() {
        super.setUp()

        context = DatabaseProvider.testInMempory(containerName: databaseContainerName).context
        testModelRepository = .live(usingClient: DatabaseClient(context: context))
    }

    override func tearDown() {
        testModelRepository = nil
        context = nil
        subscriptions = []

        super.tearDown()
    }
}

// MARK: - TestDatabase to be loaded from the Bundle as a resource

private class TestDatabase: Database {
    override var newPersistentContainer: NSPersistentContainer {
        guard let modelURL = Bundle.module.url(forResource: containerName, withExtension: "momd") else {
            fatalError("Failed to get CoreData model resource.")
        }

        guard let model = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Failed to create NSManagedObjectModel from resource.")
        }

        return NSPersistentContainer(name: containerName, managedObjectModel: model)
    }
}

// MARK: - DatabaseProvider instances with TestDatabase

private extension DatabaseProvider {
    static func testLive(onURL url: URL, containerName: String) -> Self {
        .init(database: TestDatabase(databaseType: .persistant(url: url), containerName: containerName))
    }

    static func testInMempory(containerName: String) -> Self {
        .init(database: TestDatabase(databaseType: .inMemory, containerName: containerName))
    }
}

// MARK: - Helper functions

extension DatabaseClientTests {
    func assertNoRecords<DatabaseModel: NSManagedObject>(for modelType: DatabaseModel.Type, file: String = #file, line: UInt = #line) {
        let request: NSFetchRequest<DatabaseModel> = NSFetchRequest(entityName: DatabaseModel.entityName)

        let fetch: () throws -> [DatabaseModel] = { try self.context.fetch(request) }

        let fetchResult = Result<[DatabaseModel], DatabaseError>.execute(fetch, onThrows: { DatabaseError.fetchError($0) })

        switch fetchResult {
        case let .failure(error):
            XCTFail("Unexpected result - error: \(error).")
        case let .success(databaseModels):
            XCTAssertEqual(databaseModels.count, 0)
        }
    }
}

// MARK: - Persistance tests

extension DatabaseClientTests {
    func test_database_persistance() {
        let persistanceURL = URL.documentsDirectory.appendingPathComponent("tests.sqlite")

        let databaseProvider = DatabaseProvider.testLive(onURL: persistanceURL, containerName: databaseContainerName)

        XCTAssertTrue(databaseProvider.database.deleteAndRebuild())

        testModelRepository = .live(usingClient: DatabaseClient(context: databaseProvider.context))

        let domainTestModel = DomainTestModel(id: UUID(), name: "test-model-name")

        let saveResult = testModelRepository.create(domainTestModel)

        switch saveResult {
        case .success:
            ()
        case let .failure(error):
            XCTFail("Unexpected result - error: \(error).")
        }

        let loadResult = testModelRepository.load(byID: domainTestModel.id)

        switch loadResult {
        case let .success(loadedModel) where loadedModel == domainTestModel:
            ()
        default:
            XCTFail("Unexpected result.")
        }

        XCTAssertTrue(databaseProvider.database.deleteAndRebuild())
    }
}

// MARK: - Helper functions: URL+documentsDirectory

private extension URL {
    static var documentsDirectory: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]

        return documentsDirectory
    }
}

// MARK: - Helper functions: Database+deleteAndRebuild

private extension Database {
    func deleteAndRebuild() -> Bool {
        guard case let .persistant(url: url) = self.databaseType else {
            return false
        }

        do {
            try self.persistentContainer.persistentStoreCoordinator
                .destroyPersistentStore(at: url, ofType: "sqlite", options: nil)

            loadStores(for: persistentContainer)

            return true
        } catch {
            return false
        }
    }
}
