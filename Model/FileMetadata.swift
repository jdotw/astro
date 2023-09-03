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

@objc(FileMetadata)
public class FileMetadata: NSManagedObject {}

public extension FileMetadata {
    @nonobjc class func fetchRequest() -> NSFetchRequest<FileMetadata> {
        return NSFetchRequest<FileMetadata>(entityName: "FileMetadata")
    }

    @NSManaged var file: File

    @NSManaged var key: String
    @NSManaged var string: String
}

extension FileMetadata: Identifiable {
    public var id: String { key }
}
