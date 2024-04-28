//
//  TargetExportController.swift
//  Astro
//
//  Created by James Wilson on 16/9/2023.
//

import CoreData
import Foundation

class TargetExportController: ObservableObject {
    static var shared = TargetExportController()

    private var exportQueue = OperationQueue()
    private var operationsByRequst: [URL: TargetExportOperation] = [:]

    func operation(forRequest request: TargetExportRequest) -> TargetExportOperation? {
        return operationsByRequst[request.objectID.uriRepresentation()]
    }

    func performExport(request: TargetExportRequest, context: NSManagedObjectContext) {
        // Exports all the files, both light and calibration frames,
        // for a given target and arranges them in this structure:
        //
        //  Target
        //  |-> Batch 1
        //      |-> Filter 1
        //          |-> Calibration
        //          |-> Light
        //      |-> Filter 2
        //          |-> Calibration
        //          |-> Light
        //  |-> Batch 2
        //      |-> Filter 1
        //          |-> Calibration
        //          |-> Light
        //      |-> Filter 2
        //          |-> Calibration
        //          |-> Light
        let op = TargetExportOperation(request: request)
        operationsByRequst[request.objectID.uriRepresentation()] = op
        op.completionBlock = {
            // Will be called on main
            self.operationsByRequst.removeValue(forKey: request.objectID.uriRepresentation())
            if let error = op.error {
                request.status = .failed
                request.error = error.localizedDescription
            } else {
                request.status = .exported
            }
            do {
                try context.save()
            } catch {
                request.error = error.localizedDescription
            }
        }
        exportQueue.addOperation(op)
    }
}
