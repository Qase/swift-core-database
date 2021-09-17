//
//  DatabaseClientTests+observe.swift
//  HangTests
//
//  Created by Martin Troup on 16.05.2021.
//

import CoreDatabase
import Overture
import OvertureOperators
import XCTest

private extension DatabaseClientTests {
    func test_observe_single_Job_entity() {
        assertNoRecords(for: TestModel.self)

        let domainTestModel = DomainTestModel(id: UUID(), name: "test-model-name")

        let expectation = self.expectation(description: "")

        var receivedModelChanges = [DomainTestModel?]()

        testModelRepository.observe(byID: domainTestModel.id)
            .sink(
                receiveCompletion: { completion in
                    XCTFail("Unexpected completion received: \(completion).")
                },
                receiveValue: { observedModel in
                    receivedModelChanges.append(observedModel)

                    if receivedModelChanges.count == 4 {
                        expectation.fulfill()
                    }
                }
            )
            .store(in: &subscriptions)

        // Create

        let createResult = testModelRepository.create(domainTestModel)
        assertCorrect(createResult)

        // Update

        let updatedDomainTestModel = domainTestModel |> set(\DomainTestModel.name, "changed-test-model-name")
        let updateResult = testModelRepository.update(updatedDomainTestModel)
        assertCorrect(updateResult)

        // Delete
        
        let deleteResult = testModelRepository.delete(withID: domainTestModel.id)
        assertCorrect(deleteResult)

        waitForExpectations(timeout: 0.1)

        let expectedModelChanges: [DomainTestModel?] = [
            nil,
            domainTestModel,
            .init(id: domainTestModel.id, name: "changed-test-model-name"),
            nil
        ]

        XCTAssertEqual(receivedModelChanges, expectedModelChanges)
    }

    func test_observe_multiple_Job_entities() {
        assertNoRecords(for: TestModel.self)

        let domainTestModel1 = DomainTestModel(id: UUID(), name: "test-model-name-1")
        let domainTestModel2 = DomainTestModel(id: UUID(), name: "test-model-name-2")

        let expectation = self.expectation(description: "")

        var receivedTestModelsChanges = [[DomainTestModel]]()

        testModelRepository.observe()
            .sink(
                receiveCompletion: { completion in
                    XCTFail("Unexpected completion received: \(completion).")
                },
                receiveValue: { observedModels in
                    receivedTestModelsChanges.append(observedModels)

                    if receivedTestModelsChanges.count == 6 {
                        expectation.fulfill()
                    }
                }
            )
            .store(in: &subscriptions)

        // Create model 1

        var createResult = testModelRepository.create(domainTestModel1)
        assertCorrect(createResult)

        // Create model 2

        createResult = testModelRepository.create(domainTestModel2)
        assertCorrect(createResult)

        // Update model 2

        let updatedTestModel2 = domainTestModel2 |> set(\DomainTestModel.name, "changed-test-model-2")
        let updateResult = testModelRepository.update(updatedTestModel2)
        assertCorrect(updateResult)

        // Delete model 1

        var deleteResult = testModelRepository.delete(withID: domainTestModel1.id)
        assertCorrect(deleteResult)

        // Delete model 2

        deleteResult = testModelRepository.delete(withID: domainTestModel2.id)
        assertCorrect(deleteResult)

        waitForExpectations(timeout: 0.1)

        let expectedTestModelsChanges: [[DomainTestModel]] = [
            [],
            [domainTestModel1],
            [domainTestModel1, domainTestModel2],
            [domainTestModel1, .init(id: domainTestModel2.id, name: "changed-test-model-name-2")],
            [.init(id: domainTestModel2.id, name: "changed-test-model-name-2")],
            []
        ]

        XCTAssertTrue(
            zip(receivedTestModelsChanges, expectedTestModelsChanges)
                .reduce(true) { result, values in
                    Set(values.0).symmetricDifference(Set(values.1)).isEmpty && result
                }
        )
    }
}

// MARK: - Helper functions

private extension DatabaseClientTests {
    func assertCorrect(_ result: Result<Void, DatabaseError>, line: UInt = #line) {
        switch result {
        case .success:
            ()
        default:
            XCTFail("Unexpected event.")
        }
    }
}
