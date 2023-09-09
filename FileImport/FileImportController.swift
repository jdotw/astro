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
    @Published var errors = [Error]()
    @Published var files = [ImportRequestFile]()

    init() {
        print("FILEIMPORTCONTROLLER INIT")
    }

    func performImport(request: ImportRequest, completion: @escaping () -> Void) throws {
        imported = 0
        total = 0
        importing = true
        errors = []
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
                    self.errors.append(error)
                }
            }
            DispatchQueue.main.sync {
                self.importing = false
                completion()
            }
        }
    }

    private func importFiles(_ files: [ImportRequestFile]) {
        print("IMPORTING FROM:\n\(files)")
        let waitSema = DispatchSemaphore(value: 0)
        let rateSema = DispatchSemaphore(value: ProcessInfo.processInfo.processorCount)
        let group = DispatchGroup()
        for importableFile in files {
            rateSema.wait()
            group.enter()
            PersistenceController.shared.container.performBackgroundTask { context in
                guard let importer = FileImporter.importer(forURL: importableFile.url, context: context) else {
                    rateSema.signal()
                    return
                }
                DispatchQueue.main.sync {
                    importableFile.status = .importing
                }
                importer.importFile { file, error in
                    guard error == nil, let file = file else {
                        print("Failed to import \(importableFile.url): \(error!)")
                        DispatchQueue.main.sync {
                            self.imported += 1
                            importableFile.error = error
                            importableFile.status = .failed
                        }
                        rateSema.signal()
                        group.leave()
                        return
                    }
                    let processor = FileProcessOperation(fileObjectID: file.objectID, context: context)
                    processor.completionBlock = {
                        DispatchQueue.main.sync {
                            self.imported += 1
                            importableFile.error = nil
                            importableFile.status = .imported
                        }
                        rateSema.signal()
                        group.leave()
                    }
                    FileProcessController.shared.queue.addOperation(processor)
                }
            }
        }
        group.notify(queue: .global()) {
            waitSema.signal()
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
