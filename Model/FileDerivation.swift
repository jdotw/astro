//
//  FileDerivation.swift
//
//
//  Created by James Wilson on 26/11/2023.
//
//  This file was NOT automatically generated and can be edited
//  We had to do this because CoreData is so bad.
//

import CoreData
import CoreGraphics
import CoreImage
import Foundation

@objc(FileDerivation)
public class FileDerivation: NSManagedObject {}

public enum DerivationProcess: String, CaseIterable, Identifiable {
    public var id: Self { self }
    case unknown
    case integration
    case calibration
}

public extension FileDerivation {
    @nonobjc class func fetchRequest() -> NSFetchRequest<FileDerivation> {
        return NSFetchRequest<FileDerivation>(entityName: "FileDerivation")
    }

    @NSManaged var timestamp: Date
    @NSManaged var processRawValue: String

    @NSManaged var input: File
    @NSManaged var output: File

    var process: DerivationProcess {
        get {
            DerivationProcess(rawValue: self.processRawValue) ?? .unknown
        }
        set {
            self.processRawValue = newValue.rawValue
        }
    }
}

extension FileDerivation: Identifiable {
    public var id: URL {
        objectID.uriRepresentation()
    }
}
