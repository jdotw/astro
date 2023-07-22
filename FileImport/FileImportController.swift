//
//  FileImportController.swift
//  Astro
//
//  Created by James Wilson on 19/7/2023.
//

import Foundation
import SwiftUI

class FileImportController: ObservableObject {
    @Published var imported = 0
    @Published var total = 0
    @Published var importing = false

    func performImport(request: ImportRequest, completion: @escaping () -> Void) throws {
        imported = 0
        total = 0
        importing = true

        // Resolve security-scoped URLs from bookmarks
        let resolvedURLs = try request.resolvedURLs
        try resolvedURLs.forEach { url in
            guard url.startAccessingSecurityScopedResource() else {
                throw FileImportControllerError.failedToAccessSecurityScopedURL(url)
            }
        }

        // Build file list
        let fileLists = try buildFileLists(fromURLs: resolvedURLs)
        fileLists.forEach { list in
            self.total += list.files.count
        }

        // Start background import
        importFrom(fileLists: fileLists) {
            self.importing = false
            resolvedURLs.forEach { url in
                url.stopAccessingSecurityScopedResource()
            }
            completion()
        }
    }

    func buildFileLists(fromURLs urls: [URL]) throws -> [ImportFileList] {
        var fileLists = [ImportFileList]()
        for url in urls {
            let fileList = try ImportFileList(at: url)
            fileLists.append(fileList)
        }
        return fileLists
    }

    func importFrom(fileLists: [ImportFileList], completion: @escaping () -> Void) {
        DispatchQueue.global().async {
            let importDispatchGroup = DispatchGroup()
            let importSemaphore = DispatchSemaphore(value: ProcessInfo.processInfo.processorCount)
            for fileList in fileLists {
                importDispatchGroup.enter()
                let fileListGroup = DispatchGroup()
                for fileURL in fileList.files {
                    fileListGroup.enter()
                    importSemaphore.wait()
                    PersistenceController.shared.container.performBackgroundTask { context in
                        guard let importer = FileImporter.importer(forURL: fileURL, context: context) else {
                            importSemaphore.signal()
                            fileListGroup.leave()
                            return
                        }
                        importer.importFile { _, _ in
                            DispatchQueue.main.async {
                                self.imported += 1
                            }
                            importSemaphore.signal()
                            fileListGroup.leave()
                        }
                    }
                }
                fileListGroup.notify(queue: .main) {
                    importDispatchGroup.leave()
                }
            }
            importDispatchGroup.notify(queue: .main) {
                completion()
            }
        }
    }
}

enum FileImportControllerError: Error {
    case noImporter(URL)
    case failedToReadURL(URL)
    case noURLs
    case failedToAccessSecurityScopedURL(URL)
    case failedToResolveBookmark
}
