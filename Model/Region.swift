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

@objc(RegionOfInterest)
public class RegionOfInterest: NSManagedObject {}

public extension RegionOfInterest {
    @nonobjc class func fetchRequest() -> NSFetchRequest<RegionOfInterest> {
        return NSFetchRequest<RegionOfInterest>(entityName: "RegionOfInterest")
    }

    @NSManaged var x: Int32
    @NSManaged var y: Int32
    @NSManaged var width: Int32
    @NSManaged var height: Int32
    @NSManaged var epochX: Int32
    @NSManaged var epochY: Int32

    @NSManaged var file: File
}

extension File: Identifiable {}
