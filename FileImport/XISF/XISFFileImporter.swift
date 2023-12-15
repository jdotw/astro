//
//  XISFFileImporter.swift
//  Astro
//
//  Created by James Wilson on 2/12/2023.
//

import CoreData
import CoreGraphics
import CryptoKit
import Foundation
import ImageIO

class XISFFileImporter: FileImporter {
    private var xisfFile: XISFFile
    var addToSession = true
    var addToTarget = true

    // MARK: API

    override init(url: URL, context: NSManagedObjectContext) {
        xisfFile = XISFFile(url: url)
        super.init(url: url, context: context)
    }

    func importFile(completion: @escaping (File) -> Void) throws -> File? {
        do {
            let file = try importFileSync()
            if let file {
                completion(file)
            }
            try context.save()
            return file
        } catch {
            switch error {
            case FileImportError.alreadyExists:
                throw error
            default:
                print("ERROR: ", error)
                throw error
            }
        }
    }

    // MARK: Internal

    private func importFileSync() throws -> File? {
        guard let fileHash = url.sha512Hash else {
            throw XISFFileImportError.hashFailed
        }

        // Look up File by fileHash
        let fileReq = NSFetchRequest<File>(entityName: "File")
        fileReq.predicate = NSPredicate(format: "contentHash == %@", fileHash)
        fileReq.fetchLimit = 1
        if let existing = try? context.fetch(fileReq).first {
            throw FileImportError.alreadyExists(existing)
        }

        // Get Headers from first Image
        guard let _ = xisfFile.parseHeaders(),
              let firstImage = xisfFile.images.first
        else {
            throw XISFFileImportError.noHeaders
        }
        let headers = firstImage.fitsKeywords
        var observationDate: Date!
        if let headerDateString = headers["DATE-OBS"]?.value {
            guard
                let headerDate = Date(fitsDate: headerDateString)
            else {
                throw XISFFileImportError.invalidObservationDate
            }
            observationDate = headerDate
        } else if let fileCreationDate = try? xisfFile.url.resourceValues(forKeys: [.creationDateKey]).creationDate {
            observationDate = fileCreationDate
        } else {
            throw XISFFileImportError.noObservationDate
        }

        var type: FileType = .unknown
        switch headers["IMAGETYP"]?.value {
        case "Flat Frame":
            type = .flat
        default:
            break
        }

        guard let bookmarkData = try? url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil) else {
            throw XISFFileImportError.noBookmark
        }
        guard let targetName = headers["OBJECT"]?.value else {
            throw XISFFileImportError.noTarget
        }
        guard
            let width = firstImage.width,
            let height = firstImage.height
        else {
            throw XISFFileImportError.noDimensions
        }

        // Get Data for First Image
        let data = try firstImage.getImageData()

        // Create UUID for this file
        let fileID = UUID()

        // Set up the documents directory
        guard let docsURL = URL.documentsDirectory else {
            throw XISFFileImportError.noDocumentsDirectory
        }
        if !FileManager.default.fileExists(atPath: docsURL.path(percentEncoded: false)) {
            try FileManager.default.createDirectory(at: docsURL, withIntermediateDirectories: true)
        }

        // Save a FP32 representation (raw data)
        let fp32URL = docsURL.appendingPathComponent("\(fileID.uuidString).fp32")
        try data.write(to: fp32URL, options: [.atomic])

        // Save a copy of the original XISF file
        let xisfURL = docsURL.appendingPathComponent("\(fileID.uuidString).xisf")
        try FileManager.default.copyItem(at: url, to: xisfURL)

        // Create the File record (we have already de-duped)
        let file = File(context: context)
        file.uuid = fileID
        file.timestamp = observationDate
        file.contentHash = fileHash
        file.name = url.lastPathComponent
        file.type = type
        file.url = url
        file.bookmark = bookmarkData
        file.fitsURL = xisfURL
        file.rawDataURL = fp32URL
        file.width = Int32(width)
        file.height = Int32(height)

        // Find/Create Target
        if addToTarget, !targetName.isUnknownTargetName {
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
        if addToSession {
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
        }

        // Create metadata entities from FITS Header Keywors
        for (key, value) in headers {
            let metadata = FileMetadata(context: context)
            metadata.key = key
            metadata.string = value.value ?? ""
            metadata.file = file
        }

        return file
    }
}

enum XISFFileImportError: Error {
    case hashFailed
    case noHeaders
    case noObservationDate
    case invalidObservationDate
    case noBookmark
    case noTarget
    case dataReadFailed
    case noDimensions
    case noDocumentsDirectory
}

extension XISFFileImportError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        default:
            return nil
        }
    }
}
