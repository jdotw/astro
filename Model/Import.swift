//
//  File+CoreDataClass.swift
//
//
//  Created by James Wilson on 13/7/2023.
//
//  This file was NOT automatically generated and can be edited
//  We had to do this because CoreData is so bad.
//

import CoreData
import Foundation

@objc(ImportRequest)
public class ImportRequest: NSManagedObject {}

public extension ImportRequest {
    @nonobjc class func fetchRequest() -> NSFetchRequest<ImportRequest> {
        return NSFetchRequest<ImportRequest>(entityName: "ImportRequest")
    }

    @NSManaged var id: String
    @NSManaged var timestamp: Date
    @NSManaged var urls: NSSet?
}

extension ImportRequest: Identifiable {}

@objc(ImportURL)
public class ImportURL: NSManagedObject {}

public extension ImportURL {
    @nonobjc class func fetchRequest() -> NSFetchRequest<ImportURL> {
        return NSFetchRequest<ImportURL>(entityName: "ImportURL")
    }

    @NSManaged var url: URL
    @NSManaged var bookmark: Data
    @NSManaged var importRequest: ImportRequest?
}
