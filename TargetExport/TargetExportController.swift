//
//  TargetExportController.swift
//  Astro
//
//  Created by James Wilson on 16/9/2023.
//

import Foundation

class TargetExportController: ObservableObject {
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
            try batch.exportFiles(to: batchURL)
        }
//        for file in files {
//            if file.status == .pending {
//                do {
//                    try FileManager.default.copyItem(at: file.source.fitsURL, to: file.destination)
//                    DispatchQueue.main.sync {
//                        file.status = .exported
//                        file.error = nil
//                    }
//                } catch {
//                    DispatchQueue.main.sync {
//                        file.status = .failed
//                        file.error = error
//                    }
//                }
//            }
//            DispatchQueue.main.sync {
//                self.exported += 1
//            }
//        }
    }
}

struct TargetExportFileBatch {
    let calibrationSession: Session
    let files: [TargetExportRequestFile]
    let lightFiles: [Filter: [TargetExportRequestFile]]
    let uniqueFilters: Set<Filter>

    init(calibrationSession: Session, files: [TargetExportRequestFile]) {
        self.calibrationSession = calibrationSession
        let files = files.filter { file in
            file.source.calibrationSession == calibrationSession
        }
        self.files = files
        var lightFiles = [Filter: [TargetExportRequestFile]]()
        self.uniqueFilters = Set(files.compactMap { $0.source.filter })
        for filter in uniqueFilters {
            let filesByFilter = files.filter { file in
                file.source.filter == filter && file.source.type.lowercased() == "light"
            }
            lightFiles[filter] = filesByFilter
        }
        self.lightFiles = lightFiles
    }

    var sessions: Set<Session> {
        return Set<Session>(files.compactMap { file in
            file.source.session
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

    func exportFiles(to url: URL) throws {
        print("UNIQUE FILTERS: ", uniqueFilters)
        try uniqueFilters.forEach { filter in
            // Create URL for Filter
            let filterURL = url.appending(path: filter.name.localizedUppercase)
            try FileManager.default.createDirectory(at: filterURL, withIntermediateDirectories: false)

            // Export Lights for this Filter
            let lightsURL = filterURL.appending(path: "Light")
            try FileManager.default.createDirectory(at: lightsURL, withIntermediateDirectories: false)
            try lightFiles[filter]?.forEach { file in
                try FileManager.default.copyItem(at: file.source.fitsURL, to: lightsURL.appending(path: file.source.name))
            }

            // Export Flats for this Filter
            let flatsURL = filterURL.appending(path: "Flat")
            try FileManager.default.createDirectory(at: flatsURL, withIntermediateDirectories: false)
            let flatFiles = (calibrationSession.files?.allObjects as? [File])?.filter { $0.filter == filter && $0.type.lowercased() == "flat" }
            try flatFiles?.forEach { flat in
                try FileManager.default.copyItem(at: flat.fitsURL, to: flatsURL.appending(path: flat.name))
            }
        }
    }
}

extension [TargetExportRequestFile] {
    var batches: [TargetExportFileBatch] {
        var batches = [TargetExportFileBatch]()
        let calibrationSessions = Set<Session>(compactMap { $0.source.calibrationSession })
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
        if FileManager.default.fileExists(atPath: url.path()) {
            var index = 1
            while FileManager.default.fileExists(atPath: url.path()) {
                index += 1
                url = appending(path: "\(path)-\(index)")
            }
        }
        return url
    }
}
