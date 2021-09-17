//
//  NSManagedObject+entityName.swift
//  Hang
//
//  Created by Martin Troup on 15.05.2021.
//

import CoreData

public extension NSManagedObject {
    static var entityName: String {
        String(describing: self)
    }
}
