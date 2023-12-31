//
//  ImportRequest.swift
//
//
//  Created by James Wilson on 13/7/2023.
//
//  This file was NOT automatically generated and can be edited
//  We had to do this because CoreData is so bad.
//

import CoreData
import Foundation

@objc(ImportRequest)
public class ImportRequest: NSManagedObject {}

public extension ImportRequest {
    @nonobjc class func fetchRequest() -> NSFetchRequest<ImportRequest> {
        return NSFetchRequest<ImportRequest>(entityName: "ImportRequest")
    }

    convenience init(url: URL) {
        // For Unit Tests
        let context = PersistenceController.shared.container.viewContext
        self.init(entity: ImportRequest.entity(), insertInto: context)
        self.timestamp = Date()
        self.urls = NSSet(array: [ImportURL(url: url, importRequest: self)])
    }

    @NSManaged var timestamp: Date
    @NSManaged var urls: NSSet?
}

extension ImportRequest: Identifiable {
    public var id: URL {
        objectID.uriRepresentation()
    }
}

extension ImportRequest {
    private var resolvedURLs: [URL] {
        get throws {
            guard let urls = urls as? Set<ImportURL> else {
                throw ImportRequestError.noURLs
            }
            var resolvedURLs = [URL]()
            for importURL in urls {
                var stale = false
                guard let resolvedURL = try? URL(resolvingBookmarkData: importURL.bookmark,
                                                 options: .withSecurityScope,
                                                 relativeTo: nil,
                                                 bookmarkDataIsStale: &stale)
                else {
                    print("Failed to get security scoped URL")
                    throw ImportRequestError.failedToResolveBookmark(importURL.url)
                }
                resolvedURLs.append(resolvedURL)
            }
            return resolvedURLs
        }
    }

    func buildFileList(from urls: [URL]) throws -> [ImportRequestFile] {
        var files = [ImportRequestFile]()
        for url in urls {
            let fileManager = FileManager.default
            let resourceValues = try url.resourceValues(forKeys: [.isDirectoryKey])
            if let isDirectory = resourceValues.isDirectory, isDirectory {
                let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles])!
                for case let fileURL as URL in enumerator {
                    let resourceValues = try fileURL.resourceValues(forKeys: [.isDirectoryKey])
                    if let isDirectory = resourceValues.isDirectory, !isDirectory {
                        let importable = ImportRequestFile(url: fileURL)
                        files.append(importable)
                    }
                }
            } else {
                let importable = ImportRequestFile(url: url)
                files.append(importable)
            }
        }
        return files
    }

    func withResolvedFileList(_ completion: @escaping (Result<[ImportRequestFile], Error>) -> Void) {
        do {
            let resolvedURLs = try self.resolvedURLs
            resolvedURLs.forEach { _ = $0.startAccessingSecurityScopedResource() }
            let files = try buildFileList(from: resolvedURLs)
            completion(.success(files))
            resolvedURLs.forEach { $0.stopAccessingSecurityScopedResource() }
        } catch {
            completion(.failure(error))
        }
    }
}

enum ImportRequestError: Error {
    case failedToResolveBookmark(URL)
    case noURLs
}

@objc(ImportURL)
public class ImportURL: NSManagedObject {}

public extension ImportURL {
    @nonobjc class func fetchRequest() -> NSFetchRequest<ImportURL> {
        return NSFetchRequest<ImportURL>(entityName: "ImportURL")
    }

    convenience init(url: URL, importRequest: ImportRequest) {
        // For Unit Tests
        let context = PersistenceController.shared.container.viewContext
        self.init(entity: ImportURL.entity(), insertInto: context)
        self.url = url
        self.importRequest = importRequest
        self.bookmark = try! url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
    }

    @NSManaged var url: URL
    @NSManaged var bookmark: Data
    @NSManaged var importRequest: ImportRequest?
}

extension ImportURL: Identifiable {
    public var id: URL {
        objectID.uriRepresentation()
    }
}

enum ImportRequestFileStatus: Int {
    case importing = 0
    case imported = 1
    case failed = 2
    case pending = 3
    case notImported = 4
}

extension ImportRequestFileStatus: Comparable {
    static func < (lhs: ImportRequestFileStatus, rhs: ImportRequestFileStatus) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

extension ImportRequestFileStatus {
    var isFinal: Bool {
        switch self {
        case .imported, .notImported, .failed: return true
        default: return false
        }
    }
}

class ImportRequestFile {
    let id = UUID()
    let url: URL
    let name: String
    var error: Error?
    var status: ImportRequestFileStatus
    var importedAt: Date?

    init(url: URL) {
        self.url = url
        self.name = url.lastPathComponent
        self.status = .pending
        self.error = nil
        self.importedAt = nil
    }
}

extension ImportRequestFile: Identifiable {}
