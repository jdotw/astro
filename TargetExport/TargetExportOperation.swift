//
//  TargetExportOperation.swift
//  Astro
//
//  Created by James Wilson on 13/11/2023.
//

import CoreData
import Foundation

class TargetExportOperation: Operation, ObservableObject {
    var request: TargetExportRequest
    
    @Published var exported = 0
    @Published var total = 0
    @Published var exporting = false
    @Published var error: Error?
    @Published var files = [TargetExportRequestFile]()
    
    init(request: TargetExportRequest) {
        self.request = request
    }
    
    override func main() {
        // Exports all the files, both light and calibration frames,
        // for a given target and arranges them in this structure:
        //
        //  Target
        //  |-> Calibration
        //      |-> Darks
        //          |-> Session
        //              |-> [dark.fits...]
        //              |-> master.xisf
        //          |-> Session
        //              |-> [dark.fits...]
        //              |-> master.xisf
        //          |-> Session
        //              |-> [dark.fits...]
        //              |-> master.xisf
        //      |-> Bias
        //          |-> Session
        //              |-> [bias.fits...]
        //              |-> master.xisf
        //          |-> Session
        //              |-> [bias.fits...]
        //              |-> master.xisf
        //      |-> Flat
        //          |-> Session
        //              |-> [flat.fits...]
        //              |-> master.xisf
        //          |-> Session
        //              |-> [flat.fits...]
        //              |-> master.xisf
        //          |-> Session
        //              |-> [flat.fits...]
        //              |-> master.xisf
        //  |-> Filter x
        //      |-> Session 1
        //          |-> Uncalibrated
        //              |-> [light.fits...]
        //          |-> Calibrated
        //              |-> [light-calibrated.xisf...]
        //      |-> Session 2
        //          |-> Uncalibrated
        //              |-> [light.fits...]
        //          |-> Calibrated
        //              |-> [light-calibrated.xisf...]
        //      |-> integrated.xisf
        //  |-> Filter y
        //      |-> Session 1
        //          |-> Uncalibrated
        //              |-> [light.fits...]
        //          |-> Calibrated
        //              |-> [light-calibrated.xisf...]
        //      |-> Session 2
        //          |-> Uncalibrated
        //              |-> [light.fits...]
        //          |-> Calibrated
        //              |-> [light-calibrated.xisf...]
        //      |-> integrated.xisf
        //
        //
        // Steps:
        //
        // 1. Get unique Set of Dark, Bias and Flat calibration sessions
        // 2. Create masters for each Dark, Bias and Flat calibration session
        // 3. Get Batches which are light files that are calibrated using
        //    the same Dark, Bias and Flat calibration sessions
        // 4. Calibrate each Batch using the master Dark, Bias and Flat for that batch
        // 5. Integrate all files for a given Filter

        DispatchQueue.main.sync {
            exporting = true
        }
        
        let waitSema = DispatchSemaphore(value: 0)
        do {
            try request.withResolvedFileList { result in
                switch result {
                case .success(let exportableFiles):
                    DispatchQueue.main.sync {
                        self.total = exportableFiles.count
                        self.files = exportableFiles
                    }
                    let waitSema = DispatchSemaphore(value: 0)
                    PersistenceController.shared.container.performBackgroundTask { context in
                        do {
                            try self.exportFiles(exportableFiles, forRequest: self.request, context: context)
                        } catch {
                            print("ERROR: ", error)
                        }
                        waitSema.signal()
                    }
                    waitSema.wait()
                case .failure(let error):
                    DispatchQueue.main.sync {
                        self.error = error
                        self.files = []
                    }
                }
                DispatchQueue.main.sync {
                    self.exporting = false
                    if let completionBlock = self.completionBlock {
                        completionBlock()
                    }
                }
                waitSema.signal()
            }
        } catch {
            DispatchQueue.main.sync {
                self.exporting = false
                self.error = error
                if let completionBlock = self.completionBlock {
                    completionBlock()
                }
            }
            waitSema.signal()
        }
        waitSema.wait()
    }
    
    private func exportFiles(_ files: [TargetExportRequestFile], forRequest request: TargetExportRequest, context: NSManagedObjectContext) throws {
        let batches = files.batches
        print("BATCHES: ", batches)
        for batch in batches {
            guard let batchPath = batch.path else {
                print("FAILED TO GET PATH FOR: ", batch)
                continue
            }
            let batchURL = request.url!.disambigutedURL(addingPath: batchPath)
            try FileManager.default.createDirectory(at: batchURL, withIntermediateDirectories: false)
            try exportFiles(inBatch: batch, to: batchURL)
            try calibrateFiles(inBatch: batch, at: batchURL, context: context)
        }
        let calibratedFiles = self.files.filter {
            $0.type == .light && $0.status == .calibrated
        }
        guard let reference = request.reference ?? calibratedFiles.first?.source else {
            throw TargetExportRequestError.noReferenceFile
        }
        let registeredFilesByFilter = try register(files: calibratedFiles,
                                                   usingReference: reference,
                                                   at: request.url!, context: context)
        try integrate(filesByFilter: registeredFilesByFilter, at: request.url!)
    }
    
    // MARK: Export
    
    private func exportFiles(inBatch batch: TargetExportFileBatch, to url: URL) throws {
        try batch.uniqueFilters.forEach { filter in
            // Create URL for Filter
            let filterURL = url.appending(path: filter.name.localizedCapitalized)
            try FileManager.default.createDirectory(at: filterURL, withIntermediateDirectories: false)
            
            // Export Lights for this Filter
            let lightsURL = filterURL.appending(path: "Light")
            try FileManager.default.createDirectory(at: lightsURL, withIntermediateDirectories: false)
            try batch.lightFilesByFilter[filter]?.forEach { file in
                guard let source = file.source else { return }
                try FileManager.default.copyItem(at: source.fitsURL,
                                                 to: lightsURL.appending(path: source.name))
            }
            
            // Export Flats for this Filter
            let flatsURL = filterURL.appending(path: "Flat")
            try FileManager.default.createDirectory(at: flatsURL, withIntermediateDirectories: false)
            let flatFiles = (batch.calibrationSession.files?.allObjects as? [File])?.filter {
                $0.filter == filter && $0.type == .flat
            }
            try flatFiles?.forEach { flat in
                try FileManager.default.copyItem(at: flat.fitsURL, to: flatsURL.appending(path: flat.name))
            }
        }
    }
    
    func calibrateFiles(inBatch batch: TargetExportFileBatch, at url: URL, context: NSManagedObjectContext) throws {
        try batch.uniqueFilters.forEach { filter in
            let filterURL = url.appending(path: filter.name.localizedCapitalized)
            let flatsURL = filterURL.appending(path: "Flat")
            
            //  - Integrated calibration frames
            guard let flatsFiles = batch.flatFilesByFilter[filter] else { return }
            let integrationOp = PixInsightIntegrationOperation(files: flatsFiles, mode: .flats)
            print("INTEGRATING FLATS for \(filter.name) in batch \(String(describing: batch.path)) using \(flatsFiles.count) flat files")
            integrationOp.main()
            guard let integratedFileObjectID = integrationOp.outputFileObjectID else { return }
            let masterFlat = context.object(with: integratedFileObjectID) as! File
            let masterFlatURL = flatsURL.appending(component: "master.xisf")
            try FileManager.default.copyItem(at: masterFlat.fitsURL, to: masterFlatURL)
            
            // - Create record of the master flat
            let masterFlatFile = TargetExportRequestFile(source: nil,
                                                         type: .flat,
                                                         status: .master,
                                                         url: masterFlatURL)
            DispatchQueue.main.sync {
                self.files.append(masterFlatFile)
                masterFlatFile.progress = .exported
            }
            
            //  - Calibrate light frames
            guard let lightFileRequests = batch.lightFilesByFilter[filter]
            else { return }
            let lightFiles = lightFileRequests.compactMap { $0.source }
            let calOp = PixInsightCalibrationOperation(files: lightFiles,
                                                       masterFlat: masterFlat)
            calOp.main()
            let calibratedURL = filterURL.appending(path: "Calibrated")
            try FileManager.default.createDirectory(at: calibratedURL, withIntermediateDirectories: false)
            for outputFileObjectID in calOp.outputFileObjectIDs {
                guard let file = context.object(with: outputFileObjectID) as? File,
                      let derivedFromLight = file.derivedLightFile
                else { continue }
                let source = file.fitsURL
                let destination = calibratedURL.appending(path: derivedFromLight.name)
                    .deletingPathExtension()
                    .appendingPathExtension("xisf")
                try FileManager.default.copyItem(at: source, to: destination)
                
                // Create record of the file
                let calFile = TargetExportRequestFile(source: file,
                                                      type: .light,
                                                      status: .calibrated,
                                                      url: destination)
                DispatchQueue.main.sync {
                    self.files.append(calFile)
                    calFile.progress = .exported
                }
            }
        }
    }
    
    // MARK: Registration
    
    func register(files: [TargetExportRequestFile], usingReference reference: File, at url: URL, context: NSManagedObjectContext) throws -> [Filter: [TargetExportRequestFile]] {
        guard let calibratedReference = files.first(where: { $0.source?.isDerived(from: reference) ?? false })?.source
        else { return [:] }
        let op = PixInsightRegistrationOperation(files: files.compactMap { $0.source },
                                                 referenceFile: calibratedReference)
        
        op.main()
        let registeredDestination = url.appending(path: "Registered")
        if !FileManager.default.fileExists(atPath: registeredDestination.path(percentEncoded: false)) {
            try FileManager.default.createDirectory(at: registeredDestination, withIntermediateDirectories: false)
        }
        
        var registeredFilesByFilter = [Filter: [TargetExportRequestFile]]()
        
        let outputFiles = op.outputFileObjectIDs.compactMap { context.object(with: $0) as? File }
        for file in outputFiles {
            let filterDestinationURL = registeredDestination.appending(path: file.filter.name.localizedCapitalized)
            
            if !FileManager.default.fileExists(atPath: filterDestinationURL.path(percentEncoded: false)) {
                do {
                    try FileManager.default.createDirectory(at: filterDestinationURL, withIntermediateDirectories: false)
                } catch {
                    print("Faield to create directory: ", filterDestinationURL)
                }
            }
            let destinationURL = filterDestinationURL.appending(path: file.name)
            
            if FileManager.default.fileExists(atPath: file.fitsURL.path(percentEncoded: false)) {
                do {
                    try FileManager.default.copyItem(at: file.fitsURL, to: destinationURL)
                } catch {
                    print("Failed to move item from \(file.fitsURL) to \(destinationURL)")
                }
                
                // Create record of file
                let registeredFile = TargetExportRequestFile(source: file,
                                                             type: .light,
                                                             status: .registered,
                                                             url: destinationURL)
                DispatchQueue.main.sync {
                    self.files.append(registeredFile)
                    registeredFile.progress = .exported
                }
                registeredFilesByFilter[file.filter, default: []].append(registeredFile)
            } else {
                // File failed to be registered
                // It was in the original data set, but was not
                // found in the output of the registration op
            }
        }
        
        return registeredFilesByFilter
    }
    
    // MARK: - Integration
    
    static func fileNameTimestamp(forDate date: Date?) -> String {
        return date?.fileNameTimestamp ?? "unknown"
    }
    
    static func integratedFileName(forFiles files: [TargetExportRequestFile], filter: Filter) -> String {
        let sortedFiles = files.sorted { a, b in
            a.source?.timestamp ?? Date() < b.source?.timestamp ?? Date()
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        dateFormatter.timeStyle = .none
        let earliestDate = sortedFiles.first?.source?.timestamp
        let latestDate = sortedFiles.last?.source?.timestamp
        let earliestDateString = TargetExportOperation.fileNameTimestamp(forDate: earliestDate)
        let latestDateString = TargetExportOperation.fileNameTimestamp(forDate: latestDate)
        let locFilterName = filter.name.localizedCapitalized.trimmingCharacters(in: .whitespacesAndNewlines)
        let fileName = "\(locFilterName)-Integrated-\(files.count)files-\(earliestDateString)-\(latestDateString)"
        return fileName
    }
    
    func integrate(filesByFilter: [Filter: [TargetExportRequestFile]], at url: URL) throws {
        let integratedURL = url.appending(path: "Integrated")
        if !FileManager.default.fileExists(atPath: integratedURL.path(percentEncoded: false)) {
            try FileManager.default.createDirectory(at: integratedURL, withIntermediateDirectories: false)
        }
        filesByFilter.forEach { (filter: Filter, files: [TargetExportRequestFile]) in
            let sourceFiles = files.compactMap { $0.source }
            let op = PixInsightIntegrationOperation(files: sourceFiles, mode: .lights)
            op.main()
            let fileName = TargetExportOperation.integratedFileName(forFiles: files, filter: filter)
            if let outputFileObjectID = op.outputFileObjectID {
                let waitSema = DispatchSemaphore(value: 0)
                PersistenceController.shared.container.performBackgroundTask { context in
                    if let outputFile = try? context.existingObject(with: outputFileObjectID) as? File {
                        try? FileManager.default.copyItem(at: outputFile.fitsURL,
                                                          to: integratedURL.appending(path: "\(fileName).xisf"))
                    }
                    waitSema.signal()
                }
                waitSema.wait()
            }
        }
    }
}

struct TargetExportFileBatch {
    let calibrationSession: Session
    let files: [TargetExportRequestFile]
    let lightFilesByFilter: [Filter: [TargetExportRequestFile]]
    let flatFilesByFilter: [Filter: [File]]
    let uniqueFilters: Set<Filter>
    
    init(calibrationSession: Session, files: [TargetExportRequestFile]) {
        self.calibrationSession = calibrationSession
        let files = files.filter { file in
            file.source?.resolvedFlatCalibrationSession == calibrationSession
        }
        self.files = files
        self.uniqueFilters = Set(files.compactMap { $0.source?.filter })
        
        var lightFilesByFilter = [Filter: [TargetExportRequestFile]]()
        var flatFilesByFilter = [Filter: [File]]()
        let calibrationFiles = calibrationSession.files?.allObjects as? [File]
        for filter in uniqueFilters {
            lightFilesByFilter[filter] = files.filter { file in
                file.source?.filter == filter && file.source?.type == .light
            }
            flatFilesByFilter[filter] = calibrationFiles?.filter { file in
                file.filter == filter && file.type == .flat
            }
        }
        self.lightFilesByFilter = lightFilesByFilter
        self.flatFilesByFilter = flatFilesByFilter
    }
    
    var sessions: Set<Session> {
        return Set<Session>(files.compactMap { file in
            file.source?.session
        })
    }
    
    var path: String? {
        let sortedSessions = sessions.sorted { a, b in
            a.date > b.date
        }
        guard let earliestSession = sortedSessions.first,
              let latestSession = sortedSessions.last
        else { return nil }
        return "\(earliestSession.dateString)-\(latestSession.dateString)"
    }
}

extension [TargetExportRequestFile] {
    func calibrationSessionFileBatches(ofType type: FileType) -> [TargetExportFileBatch] {
        var batches = [TargetExportFileBatch]()
        let calibrationSessions = Set<Session>(compactMap {
            guard let file = $0.source, let filter = $0.source?.filter else { return nil }
            return file.session?.resolvedCalibrationSession(forFilter: filter, type: type)
        })
        for session in calibrationSessions {
            let batch = TargetExportFileBatch(calibrationSession: session, files: self)
            batches.append(batch)
        }
        return batches
    }
    
    var batches: [TargetExportFileBatch] {
        var batches = [TargetExportFileBatch]()
        
        // Flat Calibration Sessions
        batches.append(contentsOf: calibrationSessionFileBatches(ofType: .flat))

        // Dark Calibration Sessions
        batches.append(contentsOf: calibrationSessionFileBatches(ofType: .dark))

        // Bias Calibration Sessions
        batches.append(contentsOf: calibrationSessionFileBatches(ofType: .bias))

        return batches
    }
}

extension URL {
    func disambigutedURL(addingPath path: String) -> URL {
        var url = appending(path: path)
        if FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) {
            var index = 1
            while FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) {
                index += 1
                url = appending(path: "\(path)-\(index)")
            }
        }
        return url
    }
}

extension File {
    var derivedLightFile: File? {
        guard let derivedFromRecords = derivedFrom?.allObjects as? [FileDerivation]
        else { return nil }
        let derivedFromFiles = derivedFromRecords.map { $0.input }
        return derivedFromFiles.first(where: { $0.type == .light })
    }
}

extension Date {
    var fileNameTimestamp: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        return dateFormatter.string(from: self)
    }
}
