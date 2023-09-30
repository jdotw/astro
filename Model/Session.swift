//
//  Session+CoreDataProperties.swift
//
//
//  Created by James Wilson on 13/7/2023.
//
//  This file was NOT automatically generated and can be edited
//  We had to do this because CoreData is so bad.
//

import CoreData
import Foundation

@objc(Session)
public class Session: NSManagedObject {}

public extension Session {
    @nonobjc class func fetchRequest() -> NSFetchRequest<Session> {
        return NSFetchRequest<Session>(entityName: "Session")
    }

    @NSManaged var dateString: String
    @NSManaged var files: NSSet?
    @NSManaged var calibratesFiles: NSSet?
}

// MARK: Generated accessors for files

public extension Session {
    @objc(addFilesObject:)
    @NSManaged func addToFiles(_ value: File)

    @objc(removeFilesObject:)
    @NSManaged func removeFromFiles(_ value: File)

    @objc(addFiles:)
    @NSManaged func addToFiles(_ values: NSSet)

    @objc(removeFiles:)
    @NSManaged func removeFromFiles(_ values: NSSet)
}

extension Session: Identifiable {
    public var id: URL {
        objectID.uriRepresentation()
    }
}
