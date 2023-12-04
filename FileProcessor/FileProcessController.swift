//
//  FileProcessController.swift
//  Astro
//
//  Created by James Wilson on 27/8/2023.
//

import CoreData
import Foundation

class FileProcessController {
    static let shared = FileProcessController()

    let queue = OperationQueue()

    static func process(fileObjectID: NSManagedObjectID) {
        let processor = FileProcessOperation(fileObjectID: fileObjectID)
        FileProcessController.shared.queue.addOperation(processor)
    }
}
