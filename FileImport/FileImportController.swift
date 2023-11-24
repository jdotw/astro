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
    @Environment(\.managedObjectContext) private var viewContext

    init() {
        print("FILEIMPORTCONTROLLER INIT")
    }

    func performImport(request: ImportRequest, completion: @escaping () -> Void) throws {
        imported = 0
        total = 0
        importing = true
        error = nil
        PersistenceController.shared.container.performBackgroundTask { context in
            request.withResolvedFileList { result in
                switch result {
                case .success(let importableFiles):
                    DispatchQueue.main.sync {
                        print("Importable: ", importableFiles)
                        self.total = importableFiles.count
                        self.files = importableFiles
                    }
                    self.importFiles(importableFiles, context: context)
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
    }

    private func syncPublish(status: ImportRequestFileStatus, ofImportableFile importableFile: ImportRequestFile, error: Error?) {
        DispatchQueue.main.sync {
            if status.isFinal {
                imported += 1
            }
            importableFile.error = error
            importableFile.status = status
        }
    }

    private func importFiles(_ files: [ImportRequestFile], context: NSManagedObjectContext) {
        print("IMPORTING FROM:\n\(files)")
        files.forEach { importableFile in
            autoreleasepool {
                guard let importer = FileImporter.importer(forURL: importableFile.url, context: context) else {
                    syncPublish(status: .notImported,
                                ofImportableFile: importableFile,
                                error: FileImportControllerError.noImporter(importableFile.url))
                    return
                }
                syncPublish(status: .importing,
                            ofImportableFile: importableFile,
                            error: nil)
                do {
                    guard let file = try importer.importFile() else {
                        return
                    }
                    importableFile.importedAt = Date()
                    let processor = FileProcessOperation(fileObjectID: file.objectID)
                    processor.completionBlock = {
                        self.syncPublish(status: .imported,
                                         ofImportableFile: importableFile,
                                         error: nil)
                    }
                    FileProcessController.shared.queue.addOperation(processor)
                } catch {
                    print("Failed to import \(importableFile.url): \(error)")
                    self.syncPublish(status: .failed,
                                     ofImportableFile: importableFile,
                                     error: error)
                    return
                }
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
