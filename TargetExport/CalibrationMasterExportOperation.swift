//
//  CalibrationMasterExportOperation.swift
//  Astro
//
//  Created by James Wilson on 4/6/2024.
//

import Foundation

class CalibrationMasterExportOperation: Operation, ObservableObject {
    var destination: URL
    var session: Session
    var type: FileType
    
    var masterURL: URL?
    var error: Error?
    
    init(destination: URL, session: Session, type: FileType) {
        self.destination = destination
        self.session = session
        self.type = type
    }
    
    override func main() {
        do {
            try exportCalibrationMaster()
        } catch {
            self.error = error
        }
    }
    
    private func exportCalibrationMaster() throws {
        // Create URL for the calibration files directory
        let folderURL = destination.appending(path: type.directoryName)
        if !FileManager.default.fileExists(atPath: folderURL.absoluteString) {
            try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: false)
        }
        
        // Create URL for the session
        let sessionURL = folderURL.appending(path: session.directoryName)
        if !FileManager.default.fileExists(atPath: sessionURL.absoluteString) {
            try FileManager.default.createDirectory(at: sessionURL, withIntermediateDirectories: false)
        }
            
        // Copy raw files
        let files = session.files?.allObjects as! [File]
        try files.forEach { file in
            try FileManager.default.copyItem(at: file.fitsURL,
                                             to: sessionURL.appending(path: file.name))
        }
            
        // Integrate all the files to create the master
        let op = PixInsightIntegrationOperation(files: files, type: type)
        op.main()
        if op.error != nil {
            // Bubble up any errors from integration and return
            error = op.error
            return
        }
        
        // Copy the file into place
        if let outputURL = op.outputURL {
            let fileName = "master.xisf"
            try FileManager.default.copyItem(at: outputURL,
                                             to: sessionURL.appending(path: fileName))
            masterURL = op.outputURL
        }
    }
}
