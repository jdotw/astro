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

@objc(File)
public class File: NSManagedObject {}

public extension File {
    @nonobjc class func fetchRequest() -> NSFetchRequest<File> {
        return NSFetchRequest<File>(entityName: "File")
    }

    @NSManaged var bookmark: Data
    @NSManaged var contentHash: String
    @NSManaged var filter: String?
    @NSManaged var id: String
    @NSManaged var name: String
    @NSManaged var timestamp: Date
    @NSManaged var type: String
    @NSManaged var url: URL
    @NSManaged var rawDataURL: URL
    @NSManaged var previewURL: URL
    @NSManaged var session: Session?
    @NSManaged var target: Target?
    @NSManaged var rejected: Bool
    @NSManaged var width: Int32
    @NSManaged var height: Int32
    @NSManaged var bitsPerComponent: Int16
    @NSManaged var bitsPerChannel: Int16
    @NSManaged var regions: NSSet?
}

extension File: Identifiable {}
