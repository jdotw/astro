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

@objc(Region)
public class Region: NSManagedObject {}

public extension Region {
    @nonobjc class func fetchRequest() -> NSFetchRequest<Region> {
        return NSFetchRequest<Region>(entityName: "Region")
    }

    convenience init(rect: CGRect, epoch: CGPoint, context: NSManagedObjectContext) {
        self.init(context: context)
        x = Int32(rect.origin.x)
        y = Int32(rect.origin.y)
        width = Int32(rect.size.width)
        height = Int32(rect.size.height)
        epochX = Int32(epoch.x)
        epochY = Int32(epoch.y)
    }

    @NSManaged var x: Int32
    @NSManaged var y: Int32
    @NSManaged var width: Int32
    @NSManaged var height: Int32
    @NSManaged var epochX: Int32
    @NSManaged var epochY: Int32

    @NSManaged var file: File
}

extension Region: Identifiable {}
