//
//  ModelConverters.swift
//  Hang
//
//  Created by Martin Troup on 14.05.2021.
//

import CoreData

public struct DatabaseModelConverter<DatabaseModel: NSManagedObject & Identifiable, DomainModel: Identifiable> {
    public let convert: (DatabaseModel, DomainModel) -> Void

    public init(_ convert: @escaping (DatabaseModel, DomainModel) -> Void) {
        self.convert = convert
    }
}

public struct DomainModelConverter<DatabaseModel: NSManagedObject & Identifiable, DomainModel: Identifiable> {
    public let convert: (DatabaseModel) -> DomainModel

    public init(_ convert: @escaping (DatabaseModel) -> DomainModel) {
        self.convert = convert
    }
}
