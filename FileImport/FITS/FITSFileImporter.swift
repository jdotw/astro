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

class FITSFileImporter: FileImporter {
    private var file: FITSFile

    // MARK: API

    override init?(url: URL, context: NSManagedObjectContext) {
        file = FITSFile(url: url)
        super.init(url: url, context: context)
    }

    override func importFile(completion: @escaping (File?, Error?) -> Void) {
        do {
            let file = try importFileSync()
            DispatchQueue.main.async {
                completion(file, nil)
            }
        } catch {
            DispatchQueue.main.async {
                completion(nil, error)
            }
        }
    }

    // MARK: Internal

    private func importFileSync() throws -> File? {
        guard let fileHash = file.fileHash else {
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
        guard let headers = file.parseHeaders(dataStartOffset: &dataStartOffset) else {
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
        guard let data = file.getImageData(fromOffset: dataStartOffset, headers: headers) else {
            throw FITSFileImportError.dataReadFailed
        }
        guard let cgImage = file.cgImage(data: data, headers: headers) else {
            throw FITSFileImportError.cgImageCreationFailed
        }

        // Create UUID for this file
        let fileID = UUID().uuidString

        // Save a TIFF representation (lossless)
        let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0] as URL
        guard let tiffData = cgImage.tiffData else {
            throw FITSFileImportError.tiffConversionFailed
        }
        let tiffURL = docsURL.appendingPathComponent("\(fileID).tiff")
        try tiffData.write(to: tiffURL, options: [.atomic])

        // Save a PNG at lower resolution (lossy)
        let resizedImage = cgImage.resize(to: CGSize(width: 256, height: 256))!
        guard let pngData = resizedImage.pngData else {
            throw FITSFileImportError.pngConversionFailed
        }
        let previewURL = docsURL.appendingPathComponent("\(fileID).png")
        try pngData.write(to: previewURL, options: [.atomic])

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
        file.rawDataURL = tiffURL
        file.previewURL = previewURL

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
    case noType
    case noBookmark
    case noTarget
    case dataConversionFailed
    case cgImageCreationFailed
    case tiffConversionFailed
    case pngConversionFailed
    case dataReadFailed
}

enum FITSFileError: Error {
    case blockTooSmall(_: Int)
}
