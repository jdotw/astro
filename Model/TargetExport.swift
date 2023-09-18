//
//  TargetExportRequest.swift
//
//
//  Created by James Wilson on 13/7/2023.
//
//  This file was NOT automatically generated and can be edited
//  We had to do this because CoreData is so bad.
//

import CoreData
import Foundation

@objc(TargetExportRequest)
public class TargetExportRequest: NSManagedObject {}

public extension TargetExportRequest {
    @nonobjc class func fetchRequest() -> NSFetchRequest<TargetExportRequest> {
        return NSFetchRequest<TargetExportRequest>(entityName: "TargetExportRequest")
    }

    convenience init(url: URL) {
        // For Unit Tests
        let context = PersistenceController.shared.container.viewContext
        self.init(entity: TargetExportRequest.entity(), insertInto: context)
        self.timestamp = Date()
        self.url = url
    }

    @NSManaged var timestamp: Date
    @NSManaged var url: URL
    @NSManaged var bookmark: Data
    @NSManaged var target: Target
    @NSManaged var completed: Bool
}

extension TargetExportRequest: Identifiable {
    public var id: URL {
        objectID.uriRepresentation()
    }
}

extension TargetExportRequest {
    func buildFileList(forDestination destinationURL: URL) throws -> [TargetExportRequestFile] {
        var exportableFiles = [TargetExportRequestFile]()
        for file in target.files?.allObjects as! [File] {
            let exportable = TargetExportRequestFile(source: file, atBaseURL: destinationURL)
            exportableFiles.append(exportable)
        }
        return exportableFiles
    }

    func withResolvedDestinationURL(_ completion: @escaping (URL) -> Void) throws {
        var stale = false
        guard let resolvedDestinationURL = try? URL(resolvingBookmarkData: bookmark,
                                                    options: .withSecurityScope,
                                                    relativeTo: nil,
                                                    bookmarkDataIsStale: &stale)
        else {
            print("Failed to get security scoped URL")
            throw TargetExportRequestError.failedToResolveDestinationBookmark(url)
        }
        guard resolvedDestinationURL.startAccessingSecurityScopedResource() else {
            throw TargetExportRequestError.failedToStartAccessingDestinationURL
        }
        completion(url)
        resolvedDestinationURL.stopAccessingSecurityScopedResource()
    }

    func performBackgroundTask(_ completion: @escaping (Result<[TargetExportRequestFile], Error>) -> Void) throws {
        try withResolvedDestinationURL { destinationURL in
            DispatchQueue.global().async {
                do {
                    let files = try self.buildFileList(forDestination: destinationURL)
                    completion(.success(files))
                } catch {
                    completion(.failure(error))
                }
            }
        }
    }
}

enum TargetExportRequestError: Error {
    case unknown
    case failedToResolveDestinationBookmark(URL)
    case failedToStartAccessingDestinationURL
}

enum TargetExportRequestFileStatus: Int {
    case failed = 0
    case exporting = 1
    case pending = 2
    case exported = 3
}

extension TargetExportRequestFileStatus: Comparable {
    static func < (lhs: TargetExportRequestFileStatus, rhs: TargetExportRequestFileStatus) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

class TargetExportRequestFile {
    let source: File
    let destination: URL!
    var error: Error?
    var status: TargetExportRequestFileStatus

    init(source: File, atBaseURL baseURL: URL) {
        self.source = source
        self.status = .pending
        self.error = nil
        do {
            self.destination = try URL(exportURLForSource: source, atBase: baseURL)
        } catch {
            self.error = error
            self.status = .failed
            self.destination = nil
        }
    }
}

extension TargetExportRequestFile: Identifiable {
    public var id: URL {
        objectID.uriRepresentation()
    }
}

extension URL {
    init(exportURLForSource source: File, atBase baseURL: URL) throws {
        let filterName = source.filter?.localizedCapitalized ?? "UnknownFilter"
        let filterURL = baseURL.appendingPathComponent(filterName)
        try FileManager.default.createDirectory(at: filterURL, withIntermediateDirectories: true, attributes: nil)
        let destination = filterURL.appendingPathComponent(source.name)
        self = destination
    }
}
