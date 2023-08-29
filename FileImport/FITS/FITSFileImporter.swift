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
        guard let observationDateString = headers["DATE-OBS"]?.value,
              let observationDate = Date(fitsDate: observationDateString)
        else {
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

        // Create UUID for this file
        let fileID = UUID().uuidString

        // Save a FP32 representation (raw data)
        let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0] as URL
        try FileManager.default.createDirectory(at: docsURL, withIntermediateDirectories: true)
        let fp32URL = docsURL.appendingPathComponent("\(fileID).fp32")
        try data.write(to: fp32URL, options: [.atomic])

        // Create the File record (we have already de-duped)
        let file = File(context: context)
        file.id = fileID
        file.timestamp = observationDate
        file.contentHash = fileHash
        file.name = url.lastPathComponent
        file.type = type
        file.url = url
        file.bookmark = bookmarkData
        file.filter = headers["FILTER"]?.value?.lowercased()
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
            newTarget.id = UUID().uuidString
            newTarget.name = targetName
            file.target = newTarget
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
            newSession.id = UUID().uuidString
            newSession.dateString = dateString
            file.session = newSession
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
    case noBookmark
    case noTarget
    case dataReadFailed
    case noDimensions
}

enum FITSFileError: Error {
    case blockTooSmall(_: Int)
}
