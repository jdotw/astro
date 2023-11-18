//
//  Filter+CoreDataClass.swift
//
//
//  Created by James Wilson on 13/7/2023.
//
//  This file was NOT automatically generated and can be edited
//  We had to do this because CoreData is so bad.
//

import CoreData
import Foundation

@objc(Filter)
public class Filter: NSManagedObject {}

public extension Filter {
    @nonobjc class func fetchRequest() -> NSFetchRequest<Filter> {
        return NSFetchRequest<Filter>(entityName: "Filter")
    }

    @NSManaged var name: String
    @NSManaged var files: NSSet?
}

extension Filter: Identifiable {
    public var id: URL {
        objectID.uriRepresentation()
    }
}

