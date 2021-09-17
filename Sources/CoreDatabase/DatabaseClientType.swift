//
//  DatabaseClientType.swift
//  Hang
//
//  Created by Martin Troup on 10.05.2021.
//

import Combine
import CoreData
import Overture
import OvertureOperators

public protocol DatabaseClientType {

    // MARK: - Load functions

    func load<DatabaseModel: NSManagedObject & Identifiable, DomainModel: Identifiable>(
        byID: AnyHashable,
        converter: (DatabaseModel) -> DomainModel
    ) -> Result<DomainModel?, DatabaseError>

    func load<DatabaseModel: NSManagedObject & Identifiable, DomainModel: Identifiable>(
        converter: (DatabaseModel) -> DomainModel
    ) -> Result<[DomainModel], DatabaseError>

    // MARK: - Create functions

    func create<DatabaseModel: NSManagedObject & Identifiable, DomainModel: Identifiable>(
        _ domainModel: DomainModel,
        converter update: (DatabaseModel, DomainModel) -> Void
    ) -> Result<Void, DatabaseError>

    // MARK: - Update functions

    func update<DatabaseModel: NSManagedObject & Identifiable, DomainModel: Identifiable>(
        _ domainModel: DomainModel,
        converter: (DatabaseModel, DomainModel) -> Void
    ) -> Result<Void, DatabaseError>

    // MARK: - Delete functions

    func delete<DatabaseModel: NSManagedObject & Identifiable>(
        ofType: DatabaseModel.Type,
        withID: AnyHashable
    ) -> Result<Void, DatabaseError>

    // MARK: - Observe functions

    func observe<DatabaseModel: NSManagedObject & Identifiable, DomainModel: Identifiable & Equatable>(
        byID: AnyHashable,
        converter: @escaping (DatabaseModel) -> DomainModel
    ) -> AnyPublisher<DomainModel?, DatabaseError>

    func observe<DatabaseModel: NSManagedObject & Identifiable, DomainModel: Identifiable & Equatable>(
        converter: @escaping (DatabaseModel) -> DomainModel
    ) -> AnyPublisher<[DomainModel], DatabaseError>
}

public extension DatabaseClientType {

    // MARK: Update function

    func update<DatabaseModel: NSManagedObject & Identifiable, DomainModel: Identifiable>(
        modelWithID modelID: AnyHashable,
        domainModelConverter: (DatabaseModel) -> DomainModel,
        databaseModelConverter: (DatabaseModel, DomainModel) -> Void,
        updateClosure: (DomainModel) -> DomainModel
    ) -> Result<Void, DatabaseError> {
        let loaded: Result<DomainModel?, DatabaseError> = load(byID: modelID, converter: domainModelConverter)

        return loaded
            .flatMap { model -> Result<Void, DatabaseError> in
                guard let model = model else {
                    return .failure(DatabaseError.nilWhenFetch)
                }

                return update(model |> updateClosure, converter: databaseModelConverter)
            }
    }

    // MARK: - Create & update function

    func createOrUpdate<DatabaseModel: NSManagedObject & Identifiable, DomainModel: Identifiable>(
        _ domainModel: DomainModel,
        converter: (DatabaseModel, DomainModel) -> Void
    ) -> Result<Void, DatabaseError> {
        create(domainModel, converter: converter)
            .flatMapError { error in
                error.cause == .objectExistsWhenCreate ? update(domainModel, converter: converter): .failure(error)
            }
    }
}
