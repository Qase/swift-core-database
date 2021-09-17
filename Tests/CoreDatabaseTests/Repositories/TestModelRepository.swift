//
//  TestModelRepository.swift
//  HangTests
//
//  Created by Martin Troup on 14.05.2021.
//

import CoreDatabase

extension DatabaseRepository where DatabaseModel == TestModel, DomainModel == DomainTestModel {
    static func live(usingClient databaseClient: DatabaseClientType) -> Self {
        .init(
            databaseClient: databaseClient,
            databaseModelConverter: .live,
            domainModelConverter: .live
        )
    }
}
