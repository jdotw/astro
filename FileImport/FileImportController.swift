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

    func performImport(request: ImportRequest, completion: @escaping () -> Void) throws {
        imported = 0
        total = 0
        importing = true
        errors = []
        request.performBackgroundTask { result in
            switch result {
            case .success(let urls):
                DispatchQueue.main.async {
                    self.total = urls.count
                }
                self.importFilesFrom(fileURLs: urls, persistentContainer: PersistenceController.shared.container)
            case .failure(let error):
                print("Failed to import: ", error)
                self.errors.append(error)
            }
            DispatchQueue.main.async {
                self.importing = false
                completion()
            }
        }
    }

    private func importFilesFrom(fileURLs: [URL], persistentContainer: NSPersistentContainer) {
        print("IMPORTING FROM:\n\(fileURLs)")
        let waitSema = DispatchSemaphore(value: 0)
        let rateSema = DispatchSemaphore(value: ProcessInfo.processInfo.processorCount)
        let group = DispatchGroup()
        for fileURL in fileURLs {
            rateSema.wait()
            group.enter()
            persistentContainer.performBackgroundTask { context in
                guard let importer = FileImporter.importer(forURL: fileURL, context: context) else {
                    rateSema.signal()
                    return
                }
                importer.importFile { _, _ in
                    DispatchQueue.main.async {
                        self.imported += 1
                    }
                    rateSema.signal()
                    group.leave()
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
