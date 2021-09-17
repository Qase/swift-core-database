//
//  DatabaseRepository.swift
//  Hang
//
//  Created by Martin Troup on 17.04.2021.
//

import Combine
import Core
import CoreData

public final class DatabaseRepository<DatabaseModel: NSManagedObject & Identifiable, DomainModel: Identifiable & Equatable> {
    private let databaseClient: DatabaseClientType
    private let databaseModelConverter: DatabaseModelConverter<DatabaseModel, DomainModel>
    private let domainModelConverter: DomainModelConverter<DatabaseModel, DomainModel>

    public required init(
        databaseClient: DatabaseClientType,
        databaseModelConverter: DatabaseModelConverter<DatabaseModel, DomainModel>,
        domainModelConverter: DomainModelConverter<DatabaseModel, DomainModel>
    ) {
        self.databaseClient = databaseClient
        self.databaseModelConverter = databaseModelConverter
        self.domainModelConverter = domainModelConverter
    }

    // MARK: - Load functions

    public func load(byID modelID: AnyHashable) -> Result<DomainModel?, DatabaseError> {
        databaseClient.load(byID: modelID, converter: domainModelConverter.convert)
    }

    public func load() -> Result<[DomainModel], DatabaseError> {
        databaseClient.load(converter: domainModelConverter.convert)
    }

    // MARK: - Create functions

    public func create(_ domainModel: DomainModel) -> Result<Void, DatabaseError> {
        databaseClient.create(domainModel, converter: databaseModelConverter.convert)
    }

    // MARK: - Update functions

    public func update(_ domainModel: DomainModel) -> Result<Void, DatabaseError> {
        databaseClient.update(domainModel, converter: databaseModelConverter.convert)
    }

    public func update(modelWithID modelID: AnyHashable, _ updateClosure: (DomainModel) -> DomainModel) -> Result<Void, DatabaseError> {
        databaseClient.update(
            modelWithID: modelID,
            domainModelConverter: domainModelConverter.convert,
            databaseModelConverter: databaseModelConverter.convert,
            updateClosure: updateClosure
        )
    }

    // MARK: - Create & update functions

    public func createOrUpdate(_ domainModel: DomainModel) -> Result<Void, DatabaseError> {
        databaseClient.createOrUpdate(domainModel, converter: databaseModelConverter.convert)
    }

    // MARK: - Delete functions

    public func delete(withID modelID: AnyHashable) -> Result<Void, DatabaseError> {
        databaseClient.delete(ofType: DatabaseModel.self, withID: modelID)
    }

    // MARK: - Observe functions

    public func observe(byID modelID: AnyHashable) -> AnyPublisher<DomainModel?, DatabaseError> {
        databaseClient.observe(byID: modelID, converter: domainModelConverter.convert)
    }

    public func observe() -> AnyPublisher<[DomainModel], DatabaseError> {
        databaseClient.observe(converter: domainModelConverter.convert)
    }
}
