//
//  TestModelConverter.swift
//  HangTests
//
//  Created by Martin Troup on 11.05.2021.
//

import CoreDatabase

extension DatabaseModelConverter where DatabaseModel == TestModel, DomainModel == DomainTestModel {
    static var live: DatabaseModelConverter<TestModel, DomainTestModel> = .init { testModel, domainTestModel in
        print("DB:", testModel)
        print("DOMAIN:", domainTestModel)
        testModel.id = domainTestModel.id
        testModel.name = domainTestModel.name
    }
}

extension DomainModelConverter where DatabaseModel == TestModel, DomainModel == DomainTestModel {
    static let live: Self = .init { testModel in
        DomainTestModel(id: testModel.id, name: testModel.name)
    }
}
