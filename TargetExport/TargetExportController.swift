//
//  TargetExportController.swift
//  Astro
//
//  Created by James Wilson on 16/9/2023.
//

import Foundation

class TargetExportController: ObservableObject {
    static var shared = TargetExportController()

    @Published var exported = 0
    @Published var total = 0
    @Published var exporting = false
    @Published var error: Error?
    @Published var files = [TargetExportRequestFile]()

    func performExport(request: TargetExportRequest, completion: @escaping () -> Void) throws {
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

        exported = 0
        total = 0
        exporting = true
        error = nil
        try request.performBackgroundTask { result in
            switch result {
            case .success(let exportableFiles):
                DispatchQueue.main.sync {
                    self.total = exportableFiles.count
                    self.files = exportableFiles
                }
                do {
                    try self.exportFiles(exportableFiles, forRequest: request)
                } catch {
                    print("ERROR: ", error)
                }
            case .failure(let error):
                DispatchQueue.main.sync {
                    self.error = error
                    self.files = []
                }
            }
            DispatchQueue.main.sync {
                self.exporting = false
                completion()
            }
        }
    }

    private func exportFiles(_ files: [TargetExportRequestFile], forRequest request: TargetExportRequest) throws {
        let batches = files.batches
        print("BATCHES: ", batches)
        for batch in batches {
            guard let batchPath = batch.path else {
                print("FAILED TO GET PATH FOR: ", batch)
                continue
            }
            let batchURL = request.url.disambigutedURL(addingPath: batchPath)
            try FileManager.default.createDirectory(at: batchURL, withIntermediateDirectories: false)
            try exportFiles(inBatch: batch, to: batchURL)
            try calibrateFiles(inBatch: batch, at: batchURL)
        }
        let calibratedFiles = self.files.filter {
            $0.type == .light && $0.status == .calibrated
        }
        guard let reference = request.reference ?? calibratedFiles.first?.source else {
            throw TargetExportRequestError.noReferenceFile
        }
        try register(files: calibratedFiles, usingReference: reference, at: request.url)
    }

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
                $0.filter == filter && $0.type.lowercased() == "flat"
            }
            try flatFiles?.forEach { flat in
                try FileManager.default.copyItem(at: flat.fitsURL, to: flatsURL.appending(path: flat.name))
            }
        }
    }

    func calibrateFiles(inBatch batch: TargetExportFileBatch, at url: URL) throws {
        try batch.uniqueFilters.forEach { filter in
            let filterURL = url.appending(path: filter.name.localizedCapitalized)
            let flatsURL = filterURL.appending(path: "Flat")

            //  - Integrated calibration frames
            guard let flatsFiles = batch.flatFilesByFilter[filter] else { return }
            let integrationOp = PixInsightIntegrationOperation(files: flatsFiles)
            print("INTEGRATING FLATS for \(filter.name) in batch \(String(describing: batch.path)) using \(flatsFiles.count) flat files")
            integrationOp.main()
            guard let integrationOutputURL = integrationOp.outputURL else { return }
            let masterFlatURL = flatsURL.appending(component: "master.xisf")
            try FileManager.default.copyItem(at: integrationOutputURL, to: masterFlatURL)

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
                                                       masterFlat: masterFlatURL)
            calOp.main()
            let calibratedURL = filterURL.appending(path: "Calibrated")
            try FileManager.default.copyItem(at: calOp.outputURL, to: calibratedURL)

            // Rename UUID-based files to their original filenamess
            try lightFiles.forEach { file in
                let source = calibratedURL.appending(path: file.fitsURL.lastPathComponent)
                    .deletingPathExtension()
                    .appendingPathExtension("xisf")
                let destination = calibratedURL.appending(path: file.name)
                    .deletingPathExtension()
                    .appendingPathExtension("xisf")
                try FileManager.default.moveItem(at: source, to: destination)

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

    func register(files: [TargetExportRequestFile], usingReference reference: File, at url: URL) throws {
        let fileURLs = files.compactMap { $0.url }
        guard let calibratedReference = files.first(where: { $0.source?.id == reference.id }),
              let calibratedReferenceURL = calibratedReference.url
        else { return }
        let op = PixInsightRegistrationOperation(fileURLs: fileURLs,
                                                 referenceFileURL: calibratedReferenceURL)

        op.main()
        let registeredDestination = url.appending(path: "Registered")
        try FileManager.default.createDirectory(at: registeredDestination, withIntermediateDirectories: false)

        try files.forEach { file in
            guard let sourceFile = file.source,
                  let fileURL = file.url
            else { return }
            let sourceURL = op.outputURL.appending(path: fileURL.lastPathComponent)
            let filterDestinationURL = registeredDestination.appending(path: sourceFile.filter.name.localizedCapitalized)

            if !FileManager.default.fileExists(atPath: filterDestinationURL.path(percentEncoded: false)) {
                try FileManager.default.createDirectory(at: filterDestinationURL, withIntermediateDirectories: false)
            }
            let destinationURL = filterDestinationURL.appending(path: fileURL.lastPathComponent)
            try FileManager.default.moveItem(at: sourceURL, to: destinationURL)
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
            file.source?.calibrationSession == calibrationSession
        }
        self.files = files
        self.uniqueFilters = Set(files.compactMap { $0.source?.filter })

        var lightFilesByFilter = [Filter: [TargetExportRequestFile]]()
        var flatFilesByFilter = [Filter: [File]]()
        let calibrationFiles = calibrationSession.files?.allObjects as? [File]
        for filter in uniqueFilters {
            lightFilesByFilter[filter] = files.filter { file in
                file.source?.filter == filter && file.source?.type.lowercased() == "light"
            }
            flatFilesByFilter[filter] = calibrationFiles?.filter { file in
                file.filter == filter && file.type.lowercased() == "flat"
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
            a.dateString > b.dateString
        }
        guard let earliestSession = sortedSessions.first,
              let latestSession = sortedSessions.last
        else { return nil }
        return "\(earliestSession.dateString)-\(latestSession.dateString)"
    }
}

extension [TargetExportRequestFile] {
    var batches: [TargetExportFileBatch] {
        var batches = [TargetExportFileBatch]()
        let calibrationSessions = Set<Session>(compactMap { $0.source?.calibrationSession })
        for session in calibrationSessions {
            let batch = TargetExportFileBatch(calibrationSession: session, files: self)
            batches.append(batch)
        }
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
