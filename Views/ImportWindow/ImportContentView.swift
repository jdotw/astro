//
//  ImportContentView.swift
//  Astro
//
//  Created by James Wilson on 15/7/2023.
//

import CoreData
import SwiftUI

struct ImportState {
    var importedCount: Int
    var totalCount: Int
}

struct ImportContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var importRequestID: ImportRequest.ID?
    @State var importState = ImportState(importedCount: 0, totalCount: 0)

    var body: some View {
        VStack {
            Text("Importing...")
            Text("ID: \(importEntity?.id ?? "no entity")")
            ProgressView(value: Float(importState.importedCount) / Float(importState.totalCount), total: 1.0)
        }.padding()
            .task {
                performImport()
            }
    }

    var importEntity: ImportRequest? {
        guard let importRequestID = importRequestID
        else {
            return nil
        }
        let req = ImportRequest.fetchRequest()
        req.predicate = NSPredicate(format: "id == %@", importRequestID)
        return try? viewContext.fetch(req).first
    }

    private func importFITSFileFromURL(_ url: URL) {
        print("URL: \(url)")
        guard let fits = FITSFile(url: url),
              let headers = fits.headers else { return }
        print(headers)
        do {
            _ = try fits.importFile(context: viewContext)
        } catch {
            print(error)
        }
    }

    private func importFileFromURL(_ url: URL, completion: @escaping () -> Void) {
        DispatchQueue.global().async {
            if url.isFITS {
                importFITSFileFromURL(url)
            }
            DispatchQueue.main.async { completion() }
        }
    }

    func performImport() {
        guard let importEntity = importEntity,
              let importURLs = importEntity.urls as? Set<ImportURL>
        else {
            return
        }
        for importURL in importURLs {
            print("Import from: ", importURL.url)
            var stale = false
            guard let resolvedURL = try? URL(resolvingBookmarkData: importURL.bookmark,
                                             options: .withSecurityScope,
                                             relativeTo: nil,
                                             bookmarkDataIsStale: &stale)
            else {
                print("Failed to get security scoped URL to", importURL.url)
                continue
            }

            if resolvedURL.startAccessingSecurityScopedResource() {
                guard let resourceValues = try? resolvedURL.resourceValues(forKeys: Set<URLResourceKey>([.isDirectoryKey])),
                      let isDirectory = resourceValues.isDirectory
                else {
                    continue
                }
                var urls: [URL] = []
                if isDirectory {
                    let enumerator = FileManager.default.enumerator(at: resolvedURL, includingPropertiesForKeys: nil)
                    while let childURL = enumerator?.nextObject() as? URL {
                        urls.append(childURL)
                    }
                } else {
                    urls.append(resolvedURL)
                }
                importState.totalCount += urls.count
                let group = DispatchGroup()
                for url in urls {
                    group.enter()
                    importFileFromURL(url) {
                        importState.importedCount += 1
                        group.leave()
                    }
                }
                group.notify(queue: .main) {
                    resolvedURL.stopAccessingSecurityScopedResource()
                }
            }
        }
    }
}
