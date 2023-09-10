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
    @Published var error: Error?
    @Published var files = [ImportRequestFile]()

    init() {
        print("FILEIMPORTCONTROLLER INIT")
    }

    func performImport(request: ImportRequest, completion: @escaping () -> Void) throws {
        imported = 0
        total = 0
        importing = true
        error = nil
        request.performBackgroundTask { result in
            switch result {
            case .success(let importableFiles):
                DispatchQueue.main.sync {
                    print("Importable: ", importableFiles)
                    self.total = importableFiles.count
                    self.files = importableFiles
                }
                self.importFiles(importableFiles)
            case .failure(let error):
                print("Failed to import: ", error)
                DispatchQueue.main.sync {
                    self.error = error
                }
            }
            DispatchQueue.main.sync {
                self.importing = false
                completion()
            }
        }
    }

    let waitSema = DispatchSemaphore(value: 0)
    let rateSema = DispatchSemaphore(value: ProcessInfo.processInfo.processorCount)
    let group = DispatchGroup()

    private func syncPublish(status: ImportRequestFileStatus, ofImportableFile importableFile: ImportRequestFile, error: Error?) {
        DispatchQueue.main.sync {
            if status.isFinal {
                imported += 1
            }
            importableFile.error = error
            importableFile.status = status
        }
        if status.isFinal {
            rateSema.signal()
            group.leave()
        }
    }

    private func importFiles(_ files: [ImportRequestFile]) {
        print("IMPORTING FROM:\n\(files)")
        for importableFile in files {
            rateSema.wait()
            group.enter()
            PersistenceController.shared.container.performBackgroundTask { context in
                guard let importer = FileImporter.importer(forURL: importableFile.url, context: context) else {
                    self.syncPublish(status: .notImported,
                                     ofImportableFile: importableFile,
                                     error: FileImportControllerError.noImporter(importableFile.url))
                    return
                }
                self.syncPublish(status: .importing,
                                 ofImportableFile: importableFile,
                                 error: nil)
                importer.importFile { file, error in
                    guard error == nil, let file = file else {
                        print("Failed to import \(importableFile.url): \(error!)")
                        self.syncPublish(status: .failed,
                                         ofImportableFile: importableFile,
                                         error: error)
                        return
                    }
                    let processor = FileProcessOperation(fileObjectID: file.objectID, context: context)
                    processor.completionBlock = {
                        self.syncPublish(status: .imported,
                                         ofImportableFile: importableFile,
                                         error: nil)
                    }
                    FileProcessController.shared.queue.addOperation(processor)
                }
            }
        }
        group.notify(queue: .global()) {
            self.waitSema.signal()
        }
        waitSema.wait()
    }
}

enum FileImportControllerError: Error {
    case noImporter(URL)
    case failedToReadURL(URL)
    case noURLs
    case failedToAccessSecurityScopedURL(URL)
    case failedToResolveBookmark
}

extension FileImportControllerError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .noImporter:
            return NSLocalizedString("File type is unknown", comment: "no importer")
        default:
            return nil
        }
    }
}
