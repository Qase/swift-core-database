//
//  DatabaseClient.swift
//  Hang
//
//  Created by Martin Troup on 10.05.2021.
//

import Combine
import CoreData
import Overture
import OvertureOperators

// MARK: - DatabaseClientType live implementation

public final class DatabaseClient {
    private let context: NSManagedObjectContext

    public init(context: NSManagedObjectContext) {
        self.context = context
    }
}

// MARK: - DatabaseClient + DatabaseClientType

extension DatabaseClient: DatabaseClientType {
    // MARK: - Load functions

    private func load<DatabaseModel: NSManagedObject & Identifiable>(byID modelID: AnyHashable) -> Result<DatabaseModel?, DatabaseError> {
        let request: NSFetchRequest<DatabaseModel> = FetchRequest.entity() |> FetchRequest.single(withID: modelID)

        return context.fetch(request)
            .flatMap { databaseModels in
                if databaseModels.isEmpty {
                    return .success(nil)
                }

                guard databaseModels.count == 1, let databaseModel = databaseModels.first else {
                    return .failure(.fetchError(nil))
                }

                return .success(databaseModel)
            }
    }

    public func load<DatabaseModel: NSManagedObject & Identifiable, DomainModel: Identifiable>(
        byID modelID: AnyHashable,
        converter: (DatabaseModel) -> DomainModel
    ) -> Result<DomainModel?, DatabaseError> {
        load(byID: modelID)
            .map { $0.map(converter) }
    }

    public func load<DatabaseModel: NSManagedObject & Identifiable, DomainModel: Identifiable>(
        converter: (DatabaseModel) -> DomainModel
    ) -> Result<[DomainModel], DatabaseError> {
        let request: NSFetchRequest<DatabaseModel> = FetchRequest.entity()

        return context.fetch(request)
            .map { $0.map(converter) }
    }

    // MARK: - Create functions

    public func create<DatabaseModel: NSManagedObject & Identifiable, DomainModel: Identifiable>(
        _ domainModel: DomainModel,
        converter update: (DatabaseModel, DomainModel) -> Void
    ) -> Result<Void, DatabaseError> {
        let loaded: Result<DatabaseModel?, DatabaseError> = load(byID: domainModel.id)

        switch loaded {
        case let .failure(error):
            return .failure(error)
        case let .success(object) where object == nil:
            let newDatabaseModel = DatabaseModel(context: context)
            update(newDatabaseModel, domainModel)

            return context.saveOrRollback()
        case .success:
            return .failure(.objectExistsWhenCreate)
        }
    }

    // MARK: - Update functions

    public func update<DatabaseModel: NSManagedObject & Identifiable, DomainModel: Identifiable>(
        _ domainModel: DomainModel,
        converter update: (DatabaseModel, DomainModel) -> Void
    ) -> Result<Void, DatabaseError> {
        let loaded: Result<DatabaseModel?, DatabaseError> = load(byID: domainModel.id)

        return loaded
            .flatMap { object -> Result<Void, DatabaseError> in
                object.map { .success(update($0, domainModel)) } ?? .failure(.nilWhenFetch)
            }
            .flatMap(context.saveOrRollback)
    }

    // MARK: - Delete functions

    public func delete<DatabaseModel: NSManagedObject & Identifiable>(
        ofType type: DatabaseModel.Type,
        withID modelID: AnyHashable
    ) -> Result<Void, DatabaseError> {
        let loaded: Result<DatabaseModel?, DatabaseError> = load(byID: modelID)

        return loaded
            .map { $0.map(context.delete) }
    }

    // MARK: - Observe functions

    public func observe<DatabaseModel: NSManagedObject & Identifiable, DomainModel: Identifiable & Equatable>(
        byID modelID: AnyHashable,
        converter: @escaping (DatabaseModel) -> DomainModel
    ) -> AnyPublisher<DomainModel?, DatabaseError> {
        let request: NSFetchRequest<DatabaseModel> = FetchRequest.entity() |> FetchRequest.single(withID: modelID)
            <> FetchRequest.sorted()

        return context.fetchPublisher(specifiedBy: request)
            .mapError { _ in DatabaseError.observeError }
            .flatMapResult { objects -> Result<DomainModel?, DatabaseError> in
                if objects.isEmpty {
                    return .success(nil)
                }

                guard objects.count == 1, let object = objects.first else {
                    return .failure(.observeError)
                }

                return .success(converter(object))
            }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    public func observe<DatabaseModel: NSManagedObject & Identifiable, DomainModel: Identifiable & Equatable>(
        converter: @escaping (DatabaseModel) -> DomainModel
    ) -> AnyPublisher<[DomainModel], DatabaseError> {
        let request: NSFetchRequest<DatabaseModel> = FetchRequest.entity() |> FetchRequest.sorted()

        return context.fetchPublisher(specifiedBy: request)
            .mapError { _ in DatabaseError.observeError }
            .map { objects in
                objects.map(converter)
            }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

}

// MARK: - NSManagedObjectContext + saveOrRollback

private extension NSManagedObjectContext {
    func saveOrRollback() -> Result<Void, DatabaseError> {
        guard hasChanges else { return .success(()) }

        do {
            try save()

            return .success(())
        } catch let error {
            rollback()

            return .failure(.saveError(error))
        }
    }
}

// MARK: - NSManagedObjectContext + fetch

private extension NSManagedObjectContext {
    func fetch<DatabaseModel: NSManagedObject>(_ request: NSFetchRequest<DatabaseModel>) -> Result<[DatabaseModel], DatabaseError> {
        .execute({ try self.fetch(request) }, onThrows: { .fetchError($0) })
    }
}
