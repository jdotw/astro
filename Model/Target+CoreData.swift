//
//  Target+CoreDataClass.swift
//
//
//  Created by James Wilson on 13/7/2023.
//
//  This file was NOT automatically generated and can be edited
//  We had to do this because CoreData is so bad.
//

import CoreData
import Foundation

@objc(Target)
public class Target: NSManagedObject {}

public extension Target {
    @nonobjc class func fetchRequest() -> NSFetchRequest<Target> {
        return NSFetchRequest<Target>(entityName: "Target")
    }

    @NSManaged var id: String
    @NSManaged var name: String
    @NSManaged var files: NSSet?
}

public extension Target {
    @objc(addFilesObject:)
    @NSManaged func addToFiles(_ value: File)

    @objc(removeFilesObject:)
    @NSManaged func removeFromFiles(_ value: File)

    @objc(addFiles:)
    @NSManaged func addToFiles(_ values: NSSet)

    @objc(removeFiles:)
    @NSManaged func removeFromFiles(_ values: NSSet)
}

extension Target: Identifiable {}
