//
//  TargetBatch.swift
//  Astro
//
//  Created by James Wilson on 12/11/2023.
//

import Foundation

struct TargetFileBatch {
    let calibrationSession: Session
    let files: [File]
    let uniqueFilters: Set<Filter>
    let lightFilesByFilter: [Filter: [File]]
    let flatFilesByFilter: [Filter: [File]]

    static func batches(forFiles files: [File]) -> [TargetFileBatch] {
        var batches = [TargetFileBatch]()
        let calibrationSessions = Set<Session>(files.compactMap { $0.calibrationSession })
        for session in calibrationSessions {
            let batch = TargetFileBatch(calibrationSession: session, files: files)
            batches.append(batch)
        }
        return batches
    }

    init(calibrationSession: Session, files: [File]) {
        self.calibrationSession = calibrationSession
        let files = files.filter { file in
            file.calibrationSession == calibrationSession
        }
        self.files = files
        self.uniqueFilters = Set(files.compactMap { $0.filter })

        var lightFilesByFilter = [Filter: [File]]()
        var flatFilesByFilter = [Filter: [File]]()
        let calibrationFiles = calibrationSession.files?.allObjects as? [File]
        for filter in uniqueFilters {
            lightFilesByFilter[filter] = files.filter { file in
                file.filter == filter && file.type.lowercased() == "light"
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
            file.session
        })
    }

    var name: String {
        let sortedSessions = sessions.sorted { a, b in
            a.dateString < b.dateString
        }
        guard let earliestSession = sortedSessions.first,
              let latestSession = sortedSessions.last
        else { return "unknown" }
        return "\(earliestSession.dateString)-\(latestSession.dateString)"
    }

//    func exportFiles(to url: URL) throws {
//        print("UNIQUE FILTERS: ", uniqueFilters)
//        try uniqueFilters.forEach { filter in
//            // Create URL for Filter
//            let filterURL = url.appending(path: filter.name.localizedUppercase)
//            try FileManager.default.createDirectory(at: filterURL, withIntermediateDirectories: false)
//
//            // Export Lights for this Filter
//            let lightsURL = filterURL.appending(path: "Light")
//            try FileManager.default.createDirectory(at: lightsURL, withIntermediateDirectories: false)
//            try lightFiles[filter]?.forEach { file in
//                try FileManager.default.copyItem(at: file.source.fitsURL, to: lightsURL.appending(path: file.source.name))
//            }
//
//            // Export Flats for this Filter
//            let flatsURL = filterURL.appending(path: "Flat")
//            try FileManager.default.createDirectory(at: flatsURL, withIntermediateDirectories: false)
//            let flatFiles = (calibrationSession.files?.allObjects as? [File])?.filter { $0.filter == filter && $0.type.lowercased() == "flat" }
//            try flatFiles?.forEach { flat in
//                try FileManager.default.copyItem(at: flat.fitsURL, to: flatsURL.appending(path: flat.name))
//            }
//        }
//    }
}

// extension URL {
//    func disambigutedURL(addingPath path: String) -> URL {
//        var url = appending(path: path)
//        if FileManager.default.fileExists(atPath: url.path()) {
//            var index = 1
//            while FileManager.default.fileExists(atPath: url.path()) {
//                index += 1
//                url = appending(path: "\(path)-\(index)")
//            }
//        }
//        return url
//    }
// }
