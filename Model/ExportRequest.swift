//
//  ExportRequest.swift
//  Astro
//
//  Created by James Wilson on 26/12/2024.
//
//  This file was NOT automatically generated and can be edited
//  We had to do this because CoreData is so bad.
//


import CoreData
import Foundation

// MARK: ExportRequest

@objc(ExportRequest)
public class ExportRequest: NSManagedObject {}

public enum ExportRequestStatus: String, CaseIterable, Identifiable {
    public var id: Self { self }
    case notStarted
    case inProgress
    case exported
    case failed
    case cancelled
}

enum ExportRequestError: Error {
    case unknown
    case failedToResolveDestinationBookmark(URL)
    case failedToStartAccessingDestinationURL
    case noReferenceFile
}

public extension ExportRequest {
//    @nonobjc class func fetchRequest() -> NSFetchRequest<ExportRequest> {
//        return NSFetchRequest<ExportRequest>(entityName: "ExportRequest")
//    }

    convenience init(url: URL) {
        // For Unit Tests
        let context = PersistenceController.shared.container.viewContext
        self.init(entity: ExportRequest.entity(), insertInto: context)
        self.timestamp = Date()
        self.destination = destination
        self.statusRawValue = ExportRequestStatus.notStarted.rawValue
    }

    @NSManaged var timestamp: Date
    @NSManaged var destination: URL?
    @NSManaged var destinationBookmark: Data?
    @NSManaged var statusRawValue: String
    @NSManaged var error: String?

    var status: ExportRequestStatus {
        get {
            ExportRequestStatus(rawValue: self.statusRawValue) ?? .notStarted
        }
        set {
            self.statusRawValue = newValue.rawValue
        }
    }
}

extension ExportRequest: Identifiable {
    public var id: URL {
        objectID.uriRepresentation()
    }
}

extension ExportRequest {
//    func buildFileList(forDestination destinationURL: URL) throws -> [ExportRequestFile] {
//        var exportableFiles = [ExportRequestFile]()
//        for file in self.target.files?.allObjects as! [File] {
//            if file.isDeleted {
//                continue
//            }
//            let exportable = ExportRequestFile(source: file,
//                                                     type: file.type,
//                                                     status: .original,
//                                                     url: nil)
//            exportableFiles.append(exportable)
//        }
//        return exportableFiles
//    }

//    func withResolvedDestinationURL(_ completion: @escaping (URL) -> Void) throws {
//        var stale = false
//        guard let resolvedDestinationURL = try? URL(resolvingBookmarkData: bookmark!,
//                                                    options: .withSecurityScope,
//                                                    relativeTo: nil,
//                                                    bookmarkDataIsStale: &stale)
//        else {
//            print("Failed to get security scoped URL")
//            throw ExportRequestError.failedToResolveDestinationBookmark(self.url!)
//        }
//        guard resolvedDestinationURL.startAccessingSecurityScopedResource() else {
//            throw ExportRequestError.failedToStartAccessingDestinationURL
//        }
//        completion(self.url!)
//        resolvedDestinationURL.stopAccessingSecurityScopedResource()
//    }

//    func withResolvedFileList(_ completion: @escaping (Result<[ExportRequestFile], Error>) -> Void) throws {
//        try self.withResolvedDestinationURL { destinationURL in
//            DispatchQueue.global().async {
//                do {
//                    let files = try self.buildFileList(forDestination: destinationURL)
//                    completion(.success(files))
//                } catch {
//                    completion(.failure(error))
//                }
//            }
//        }
//    }
}

//extension ExportRequest {
//    var exportOperation: ExportOperation? {
//        return ExportController.shared.operation(forRequest: self)
//    }
//
//    var hasExportOperation: Bool {
//        return self.exportOperation != nil
//    }
//}


//
// MARK: ExportRequestFile
//

enum ExportRequestFileProgress: Int {
    case failed = 0
    case exporting = 1
    case pending = 2
    case exported = 3
}

class ExportRequestFile: Identifiable {
    let id = UUID()
    let source: File?
    var error: Error?
    let destination: URL?
    var progress: ExportRequestFileProgress
    var type: FileType

    init(source: File?,
         type: FileType,
         destination: URL?)
    {
        self.source = source
        self.progress = .pending
        self.type = type
        self.error = nil
        self.destination = destination
    }
}

//extension [ExportRequestFile] {
//    func calibrationSessions(ofType type: FileType) -> Set<Session> {
//        return Set<Session>(self.compactMap { exportFile in
//            exportFile.source?.resolvedCalibrationSession(type: type)
//        })
//    }
//
//    var uniqueFilters: Set<Filter> {
//        return Set<Filter>(self.compactMap { exportFile in
//            exportFile.source?.filter
//        })
//    }
//}

