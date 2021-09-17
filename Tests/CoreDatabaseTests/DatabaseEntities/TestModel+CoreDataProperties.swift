//
//  TestModel+CoreDataProperties.swift
//  Hang
//
//  Created by Martin Troup on 17.05.2021.
//
//

import Foundation
import CoreData


extension TestModel {
    @NSManaged public var id: UUID
    @NSManaged public var name: String

}

extension TestModel: Identifiable {

}
