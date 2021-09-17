//
//  DatabaseClientTests+CRUD.swift
//  HangTests
//
//  Created by Martin Troup on 11.05.2021.
//

import CoreData
import Overture
import OvertureOperators
import XCTest

extension DatabaseClientTests {

    // MARK: - Load functions

    func test_load_single_non_existent_entity() {
        assertNoRecords(for: TestModel.self)

        let loadResult = testModelRepository.load(byID: UUID())

        switch loadResult {
        case let .success(object) where object == nil:
            ()
        default:
            XCTFail("Unexpected result.")
        }
    }

    func test_load_all_non_existent_entity() {
        assertNoRecords(for: TestModel.self)

        let loadResult = testModelRepository.load()

        switch loadResult {
        case let .success(objects) where objects.isEmpty:
            ()
        default:
            XCTFail("Unexpected result.")
        }
    }

    // MARK: - Create + Load functions

    func test_create_and_load_single_entity() {
        assertNoRecords(for: TestModel.self)

        // Create

        let domainTestModel = DomainTestModel(id: UUID(), name: "test-model-name")

        let createResult = testModelRepository.create(domainTestModel)

        switch createResult {
        case .success:
            ()
        case let .failure(error):
            XCTFail("Unexpected result - error: \(error).")
        }

        // Load

        let loadResult = testModelRepository.load(byID: domainTestModel.id)

        switch loadResult {
        case let .success(loadedModel):
            XCTAssertEqual(loadedModel, domainTestModel)
        case let .failure(error):
            XCTFail("Unexpected result - error: \(error).")
        }
    }

    func test_create_and_load_multiple_entities() {
        assertNoRecords(for: TestModel.self)

        // Create model 1

        let domainTestModel1 = DomainTestModel(id: UUID(), name: "test-model-name")

        var createResult = testModelRepository.create(domainTestModel1)

        switch createResult {
        case .success:
            ()
        case let .failure(error):
            XCTFail("Unexpected result - error: \(error).")
        }

        // Load

        var loadResult = testModelRepository.load()

        switch loadResult {
        case let .success(loadedModels) where loadedModels.count == 1:
            XCTAssertEqual(loadedModels[0], domainTestModel1)
        default:
            XCTFail("Unexpected result.")
        }

        // Create model 2

        let domainTestModel2 = DomainTestModel(id: UUID(), name: "test-model-name")

        createResult = testModelRepository.create(domainTestModel2)

        // Load

        loadResult = testModelRepository.load()

        switch loadResult {
        case let .success(loadedModels) where loadedModels.count == 2:
            XCTAssertTrue(
                Set(loadedModels).symmetricDifference(Set([domainTestModel1, domainTestModel2])).isEmpty
            )
        default:
            XCTFail("Unexpected result.")
        }
    }

    // MARK: - Create functions

    func test_create_same_entity_twice() {
        assertNoRecords(for: TestModel.self)

        let domainTestModel = DomainTestModel(id: UUID(), name: "test-model-name")

        // Create first time

        var createResult = testModelRepository.create(domainTestModel)

        switch createResult {
        case .success:
            ()
        case let .failure(error):
            XCTFail("Unexpected result - error: \(error).")
        }

        // Create second time

        createResult = testModelRepository.create(domainTestModel)

        switch createResult {
        case let .failure(error) where error.cause == .objectExistsWhenCreate:
            ()
        default:
            XCTFail("Unexpected result.")
        }

        // Load

        let loadResult = testModelRepository.load()

        switch loadResult {
        case let .success(loadedModels) where loadedModels.count == 1:
            ()
        default:
            XCTFail("Unexpected result.")
        }
    }

    // MARK: - Delete functions

    func test_delete_entity() {
        assertNoRecords(for: TestModel.self)

        let domainTestModel = DomainTestModel(id: UUID(), name: "test-model-name")

        // Create

        let createResult = testModelRepository.create(domainTestModel)

        switch createResult {
        case .success:
            ()
        default:
            XCTFail("Unexpected result.")
        }

        // Load

        var loadResult = testModelRepository.load(byID: domainTestModel.id)

        switch loadResult {
        case let .success(loadedModel) where loadedModel == domainTestModel:
            ()
        default:
            XCTFail("Unexpected result.")
        }

        // Delete

        let deleteResult = testModelRepository.delete(withID: domainTestModel.id)

        switch deleteResult {
        case .success:
            ()
        default:
            XCTFail("Unexpected result.")
        }

        loadResult = testModelRepository.load(byID: domainTestModel.id)

        switch loadResult {
        case let .success(loadedModel) where loadedModel == nil:
            ()
        default:
            XCTFail("Unexpected result.")
        }

        assertNoRecords(for: TestModel.self)
    }

    // MARK: Update functions
    
    func test_update_success_entity() {
        assertNoRecords(for: TestModel.self)

        let domainTestModel = DomainTestModel(id: UUID(), name: "test-model-name")

        // Create

        let createResult = testModelRepository.create(domainTestModel)

        switch createResult {
        case .success:
            ()
        default:
            XCTFail("Unexpected result.")
        }

        // Load

        var loadResult = testModelRepository.load(byID: domainTestModel.id)

        switch loadResult {
        case let .success(loadedModel) where loadedModel == domainTestModel:
            ()
        default:
            XCTFail("Unexpected result.")
        }

        // Update

        let updatedModel = domainTestModel |> set(\.name, "changed-test-model-name")

        let updateResult = testModelRepository.update(updatedModel)

        switch updateResult {
        case .success:
            ()
        default:
            XCTFail("Unexpected result.")
        }

        // Load

        loadResult = testModelRepository.load(byID: domainTestModel.id)

        switch loadResult {
        case let .success(loadedModel) where loadedModel == updatedModel:
            ()
        default:
            XCTFail("Unexptected result.")
        }
    }

    func test_update_non_existent_entity() {
        assertNoRecords(for: TestModel.self)

        let domainTestModel = DomainTestModel(id: UUID(), name: "test-model-name")

        // Update

        let updatedModel = domainTestModel |> set(\.name, "changed-test-model-name")

        let updateResult = testModelRepository.update(updatedModel)

        switch updateResult {
        case let .failure(error) where error.cause == .nilWhenFetch:
            ()
        default:
            XCTFail("Unexpected result.")
        }

        // Load

        let loadResult = testModelRepository.load(byID: domainTestModel.id)

        switch loadResult {
        case let .success(loadedModel) where loadedModel == nil:
            ()
        default:
            XCTFail("Unexptected result.")
        }
    }

    func test_update_with_update_closure() {
        assertNoRecords(for: TestModel.self)

        let domainTestModel = DomainTestModel(id: UUID(), name: "test-model-name")

        // Create

        let createResult = testModelRepository.create(domainTestModel)

        switch createResult {
        case .success:
            ()
        default:
            XCTFail("Unexpected result.")
        }

        // Load

        var loadResult = testModelRepository.load(byID: domainTestModel.id)

        switch loadResult {
        case let .success(loadedModel) where loadedModel == domainTestModel:
            ()
        default:
            XCTFail("Unexpected result.")
        }

        // Update

        let updatedModel = domainTestModel |> set(\.name, "changed-test-model-name")

        let updateResult = testModelRepository.update(modelWithID: domainTestModel.id) { loadedDomainModel in
            loadedDomainModel |> set(\.name, "changed-test-model-name")
        }

        switch updateResult {
        case .success:
            ()
        default:
            XCTFail("Unexpected result.")
        }

        // Load

        loadResult = testModelRepository.load(byID: domainTestModel.id)

        switch loadResult {
        case let .success(loadedModel) where loadedModel == updatedModel:
            ()
        default:
            XCTFail("Unexptected result.")
        }
    }

    // MARK: Create & update functions

    func test_create_and_update_entity() {
        assertNoRecords(for: TestModel.self)

        let domainTestModel = DomainTestModel(id: UUID(), name: "test-model-name")

        // CreateOrUpdate - create

        var createOrUpdateResult = testModelRepository.createOrUpdate(domainTestModel)

        switch createOrUpdateResult {
        case .success:
            ()
        default:
            XCTFail("Unexpected result.")
        }

        // Load

        var loadResult = testModelRepository.load(byID: domainTestModel.id)

        switch loadResult {
        case let .success(loadedModel) where loadedModel == domainTestModel:
            ()
        default:
            XCTFail("Unexpected result.")
        }

        // CreateOrUpdate - update

        let updatedModel = domainTestModel |> set(\.name, "changed-test-model-name")

        createOrUpdateResult = testModelRepository.update(updatedModel)

        switch createOrUpdateResult {
        case .success:
            ()
        default:
            XCTFail("Unexpected result.")
        }

        // Load

        loadResult = testModelRepository.load(byID: domainTestModel.id)

        switch loadResult {
        case let .success(loadedModel) where loadedModel == updatedModel:
            ()
        default:
            XCTFail("Unexptected result.")
        }
    }
}
