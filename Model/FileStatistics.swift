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

@objc(FileStatistics)
public class FileStatistics: NSManagedObject {}

public extension FileStatistics {
    @nonobjc class func fetchRequest() -> NSFetchRequest<FileStatistics> {
        return NSFetchRequest<FileStatistics>(entityName: "FileStatistics")
    }

    @NSManaged var file: File

    @NSManaged var max: Float
    @NSManaged var median: Float
    @NSManaged var avgMedianDeviation: Float
}

extension FileStatistics: Identifiable {}
