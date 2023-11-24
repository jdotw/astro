//
//  FITSFileImport.swift
//  Astro
//
//  Created by James Wilson on 15/7/2023.
//

import CoreData
import CoreGraphics
import CryptoKit
import Foundation
import ImageIO

class FITSFileImporter: FileImporter {
    private var fitsFile: FITSFile

    // MARK: API

    override init?(url: URL, context: NSManagedObjectContext) {
        fitsFile = FITSFile(url: url)
        super.init(url: url, context: context)
    }

    override func importFile(completion: @escaping (File?, Error?) -> Void) {
        do {
            let file = try importFileSync()
            completion(file, nil)
        } catch {
            completion(nil, error)
        }
    }

    // MARK: Internal

    private func importFileSync() throws -> File? {
        guard let fileHash = fitsFile.fileHash else {
            throw FITSFileImportError.hashFailed
        }

        // Look up File by fileHash
        let fileReq = NSFetchRequest<File>(entityName: "File")
        fileReq.predicate = NSPredicate(format: "contentHash == %@", fileHash)
        fileReq.fetchLimit = 1
        if let existing = try? context.fetch(fileReq).first {
            throw FITSFileImportError.alreadyExists(existing)
        }

        // Get Headers
        var dataStartOffset: UInt64 = 0
        guard let headers = fitsFile.parseHeaders(dataStartOffset: &dataStartOffset) else {
            throw FITSFileImportError.noHeaders
        }
        var observationDate: Date!
        if let headerDateString = headers["DATE-OBS"]?.value {
            guard
                let headerDate = Date(fitsDate: headerDateString)
            else {
                throw FITSFileImportError.invalidObservationDate
            }
            observationDate = headerDate
        } else if let fileCreationDate = try? fitsFile.url.resourceValues(forKeys: [.creationDateKey]).creationDate {
            observationDate = fileCreationDate
        } else {
            throw FITSFileImportError.noObservationDate
        }

        let type = headers["FRAME"]?.value?.lowercased() ?? "light"
        guard let bookmarkData = try? url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil) else {
            throw FITSFileImportError.noBookmark
        }
        guard let targetName = headers["OBJECT"]?.value else {
            throw FITSFileImportError.noTarget
        }
        guard let widthString = headers["NAXIS1"]?.value,
              let width = Int32(widthString),
              let heightString = headers["NAXIS2"]?.value,
              let height = Int32(heightString)
        else {
            throw FITSFileImportError.noDimensions
        }

        // Get Data and Image
        guard let data = fitsFile.getImageData(fromOffset: dataStartOffset, headers: headers) else {
            throw FITSFileImportError.dataReadFailed
        }

        // Create UUID for this file]
        let fileID = UUID()

        // Set up the documents directory
        let docsURLs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        guard let docsURL = docsURLs.first?.appending(path: "Astro") else {
            throw FITSFileImportError.noDocumentsDirectory
        }
        if !FileManager.default.fileExists(atPath: docsURL.path(percentEncoded: false)) {
            try FileManager.default.createDirectory(at: docsURL, withIntermediateDirectories: true)
        }

        // Save a FP32 representation (raw data)
        let fp32URL = docsURL.appendingPathComponent("\(fileID.uuidString).fp32")
        try data.write(to: fp32URL, options: [.atomic])

        // Save a copy of the original FITS file
        let fitsURL = docsURL.appendingPathComponent("\(fileID.uuidString).fits")
        try FileManager.default.copyItem(at: url, to: fitsURL)

        // Create the File record (we have already de-duped)
        let file = File(context: context)
        file.uuid = fileID
        file.timestamp = observationDate
        file.contentHash = fileHash
        file.name = url.lastPathComponent
        file.type = type
        file.url = url
        file.bookmark = bookmarkData
        file.fitsURL = fitsURL
        file.rawDataURL = fp32URL
        file.width = width
        file.height = height

        // Find/Create Target
        let targetReq = NSFetchRequest<Target>(entityName: "Target")
        targetReq.predicate = NSPredicate(format: "name == %@", targetName)
        targetReq.fetchLimit = 1
        if let target = try? context.fetch(targetReq).first {
            file.target = target
        } else {
            let newTarget = Target(context: context)
            newTarget.name = targetName
            file.target = newTarget
        }

        // Find/Create Filter
        let filterName = headers["FILTER"]?.value?.lowercased() ?? "none"
        let filterReq = NSFetchRequest<Filter>(entityName: "Filter")
        filterReq.predicate = NSPredicate(format: "name == %@", filterName)
        filterReq.fetchLimit = 1
        if let filter = try? context.fetch(filterReq).first {
            file.filter = filter
        } else {
            let newFilter = Filter(context: context)
            newFilter.name = filterName
            file.filter = newFilter
        }

        // Find Session by dateString
        let dateString = observationDate.sessionDateString()
        let sessionReq = NSFetchRequest<Session>(entityName: "Session")
        sessionReq.predicate = NSPredicate(format: "dateString == %@", dateString)
        sessionReq.fetchLimit = 1
        if let session = try? context.fetch(sessionReq).first {
            file.session = session
        } else {
            let newSession = Session(context: context)
            newSession.dateString = dateString
            file.session = newSession
        }

        // Create metadata entities from FITS Header Keywors
        for (key, value) in headers {
            let metadata = FileMetadata(context: context)
            metadata.key = key
            metadata.string = value.value ?? ""
            metadata.file = file
        }

        try context.save()

        return file
    }
}

enum FITSFileImportError: Error {
    case hashFailed
    case alreadyExists(File)
    case noHeaders
    case noObservationDate
    case invalidObservationDate
    case noBookmark
    case noTarget
    case dataReadFailed
    case noDimensions
    case noDocumentsDirectory
}

extension FITSFileImportError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .alreadyExists:
            return NSLocalizedString("The file has already been imported", comment: "file already imported")
        default:
            return nil
        }
    }
}

enum FITSFileError: Error {
    case blockTooSmall(_: Int)
}
