//
//  NSManagedObjectContext+fetchPublisher.swift
//  Hang
//
//  Created by Martin Troup on 09.05.2021.
//

import Combine
import CoreData

extension NSManagedObjectContext {
    func fetchPublisher<Object: NSManagedObject>(specifiedBy fetchRequest: NSFetchRequest<Object>) -> Publisher<Object> {
        Publisher(fetchRequest: fetchRequest, context: self)
    }

    struct Publisher<Object: NSManagedObject>: Combine.Publisher {
        typealias Output = [Object]
        typealias Failure = Error

        private let fetchRequest: NSFetchRequest<Object>
        private let context: NSManagedObjectContext

        init(fetchRequest: NSFetchRequest<Object>, context: NSManagedObjectContext) {
            self.fetchRequest = fetchRequest
            self.context = context
        }

        func receive<S: Subscriber>(subscriber: S) where Failure == S.Failure, Output == S.Input {
            let subscription = Subscription(subscriber: subscriber, context: context, fetchRequest: fetchRequest)
            subscriber.receive(subscription: subscription)
        }
    }

    // swiftlint:disable:next colon
    private final class Subscription<S: Subscriber, Object: NSManagedObject>:
        NSObject,
        Combine.Subscription,
        NSFetchedResultsControllerDelegate
    where S.Input == [Object], S.Failure == Error {
        private var subscriber: S?
        private var requestedDemand: Subscribers.Demand = .none
        private var isRunning: Bool = false
        private var fetchedResultsController: NSFetchedResultsController<Object>?
        private var lastFetchedObjects: [Object] = []

        init(
            subscriber: S,
            context: NSManagedObjectContext,
            fetchRequest: NSFetchRequest<Object>
        ) {
            self.subscriber = subscriber
            self.fetchedResultsController = NSFetchedResultsController(
                fetchRequest: fetchRequest,
                managedObjectContext: context,
                sectionNameKeyPath: nil,
                cacheName: nil
            )

            super.init()

            fetchedResultsController?.delegate = self

            do {
                try fetchedResultsController?.performFetch()
//                updateCurrentChangesdifference()
            } catch {
                subscriber.receive(completion: .failure(error))
            }
        }

        func request(_ demand: Subscribers.Demand) {
            if demand != .none {
                requestedDemand += demand
            }

            guard !isRunning else { return }
            isRunning = true

            fulfillDemand()
        }

        // NSFetchedResultsControllerDelegate implementation
        func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
            fulfillDemand()
        }

        private func fulfillDemand() {
            let newDemand = subscriber?.receive(fetchedResultsController?.fetchedObjects ?? [])

            requestedDemand -= .max(1)

            if let newDemand = newDemand, newDemand != .none {
                self.requestedDemand += newDemand
            }
        }

        func cancel() {
            fetchedResultsController?.delegate = nil
            fetchedResultsController = nil
            subscriber = nil
        }
    }
}
