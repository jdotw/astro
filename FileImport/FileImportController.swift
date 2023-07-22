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

        // Get user-specified URLs
        guard let userSpecifiedURLs = request.urls as? Set<ImportURL>
        else {
            throw FileImportControllerError.noURLs
        }

        // Build file list
        let resolvedURLs = try resolvedURLs(fromBookmarks: userSpecifiedURLs.map(\.bookmark))
        let fileLists = try buildSecurityScopedFileLists(fromURLs: resolvedURLs)
        fileLists.forEach { list in
            self.total += list.files.count
        }

        // Start background import
        importFrom(fileLists: fileLists) {
            self.importing = false
            completion()
        }
    }

    func resolvedURLs(fromBookmarks bookmarks: [Data]) throws -> [URL] {
        var urls = [URL]()
        for bookmark in bookmarks {
            var stale = false
            do {
                let _ = try URL(resolvingBookmarkData: bookmark,
                                options: .withSecurityScope,
                                relativeTo: nil,
                                bookmarkDataIsStale: &stale)
            } catch {
                print("Failed to resolve bookmark: ", error)
                throw FileImportControllerError.failedToResolveBookmark
            }
            guard let resolvedURL = try? URL(resolvingBookmarkData: bookmark,
                                             options: .withSecurityScope,
                                             relativeTo: nil,
                                             bookmarkDataIsStale: &stale)
            else {
                print("Failed to get security scoped URL")
                throw FileImportControllerError.failedToResolveBookmark
            }
            if resolvedURL.startAccessingSecurityScopedResource() {
                urls.append(resolvedURL)
            } else {
                throw FileImportControllerError.failedToAccessSecurityScopedURL(resolvedURL)
            }
        }
        return urls
    }

    func buildSecurityScopedFileLists(fromURLs urls: [URL]) throws -> [ImportFileList] {
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
                    fileList.baseURL.stopAccessingSecurityScopedResource()
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
