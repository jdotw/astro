//
//  TargetExportRequest.swift
//
//
//  Created by James Wilson on 13/7/2023.
//
//  This file was NOT automatically generated and can be edited
//  We had to do this because CoreData is so bad.
//

import CoreData
import Foundation

@objc(TargetExportRequest)
public class TargetExportRequest: NSManagedObject {}

public extension TargetExportRequest {
    @nonobjc class func fetchRequest() -> NSFetchRequest<TargetExportRequest> {
        return NSFetchRequest<TargetExportRequest>(entityName: "TargetExportRequest")
    }

    convenience init(url: URL) {
        // For Unit Tests
        let context = PersistenceController.shared.container.viewContext
        self.init(entity: TargetExportRequest.entity(), insertInto: context)
        self.timestamp = Date()
        self.url = url
    }

    @NSManaged var timestamp: Date
    @NSManaged var url: URL
    @NSManaged var bookmark: Data
    @NSManaged var target: Target
}

extension TargetExportRequest: Identifiable {
    public var id: URL {
        self.objectID.uriRepresentation()
    }
}

enum TargetExportRequestError: Error {
    case unknown
}

enum TargetExportRequestStatus: Int {
    case failed = 0
    case exporting = 1
    case done = 2
}
