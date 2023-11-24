//
//  FileImport.swift
//  Astro
//
//  Created by James Wilson on 15/7/2023.
//

import CoreData
import Foundation

class FileImporter: ObservableObject {
    var url: URL
    var context: NSManagedObjectContext

    class func importer(forURL url: URL, context: NSManagedObjectContext) -> FileImporter? {
        switch url.pathExtension {
        case "fits", "fit":
            return FITSFileImporter(url: url, context: context)
        default:
            return nil
        }
    }

    init?(url: URL, context: NSManagedObjectContext) {
        self.url = url
        self.context = context
    }

    func importFile() throws -> File? {
        fatalError("importFile() must be overridden")
    }
}
