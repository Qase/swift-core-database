//
//  DatabaseError.swift
//  Hang
//
//  Created by Martin Troup on 17.04.2021.
//

import Core
import Foundation

public struct DatabaseError: ErrorReportable {
    // MARK: - Cause

    public enum ErrorCause: Error, CustomDebugStringConvertible, Equatable {
        case fetchError(Error?)
        case nilWhenFetch
        case objectExistsWhenCreate
        case saveError(Error)
        case deleteError(Error)
        case observeError

        public var debugDescription: String {
            switch self {
            case let .fetchError(error):
                return "ErrorCause.fetchError(error: \(String(describing: error)))."
            case .nilWhenFetch:
                return "ErrorCause.nilWhenFetch."
            case .objectExistsWhenCreate:
                return "ErrorCause.objectExistsWhenCreate"
            case let .saveError(error):
                return "ErrorCause.saveError(error: \(error))."
            case let .deleteError(error):
                return "ErrorCause.deleteError(error: \(error))."
            case .observeError:
                return "ErrorCause.observeError"
            }
        }

        public static func == (lhs: DatabaseError.ErrorCause, rhs: DatabaseError.ErrorCause) -> Bool {
            switch (lhs, rhs) {
            case (.fetchError, .fetchError):
                return true
            case (.nilWhenFetch, .nilWhenFetch):
                return true
            case (.objectExistsWhenCreate, .objectExistsWhenCreate):
                return true
            case (.saveError, .saveError):
                return true
            case (.deleteError, .deleteError):
                return true
            case (.observeError, .observeError):
                return true
            default:
                return false
            }
        }
    }

    public var causeDescription: CustomDebugStringConvertible? { cause.debugDescription }

    // MARK: - Properties

    public let catalogueID = ErrorCatalogueID.unassigned
    public let cause: ErrorCause
    public var stackID: UUID?
    public var underlyingError: ErrorReportable?

    // MARK: - Initializers

    public init(cause: ErrorCause, stackID: UUID? = nil) {
        self.cause = cause
        self.stackID = stackID ?? UUID()
    }
}

// MARK: - NetworkError instances

public extension DatabaseError {
    static var fetchError: (Error?) -> Self {
        { .init(cause: .fetchError($0)) }
    }

    static var saveError: (Error) -> Self {
        { .init(cause: .saveError($0)) }
    }

    static var nilWhenFetch: Self {
        .init(cause: .nilWhenFetch)
    }

    static var objectExistsWhenCreate: Self {
        .init(cause: .objectExistsWhenCreate)
    }

    static var deleteError: (Error) -> Self {
        { .init(cause: .deleteError($0)) }
    }

    static var observeError: Self {
        .init(cause: .observeError)
    }
}
