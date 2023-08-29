//
//  FileProcessOperation.swift
//  Astro
//
//  Created by James Wilson on 27/8/2023.
//

import CoreData
import CoreGraphics
import Foundation

class FileProcessOperation: Operation {
    var fileObjectID: NSManagedObjectID
    var context: NSManagedObjectContext

    init(fileObjectID: NSManagedObjectID, context: NSManagedObjectContext) {
        self.fileObjectID = fileObjectID
        self.context = context
    }

    override func main() {
        // Retrieve file
        guard let file = context.object(with: fileObjectID) as? File else {
            print("PROCESSOR: Failed to get file!")
            return
        }
        print("Processing: \(file)")

        // Get image statistics
        guard let stats = file.getStatistics() else {
            print("PROCESSOR: Failed to get image stats!")
            return
        }
        file.statistics = FileStatistics(context: context)
        file.statistics?.median = stats.median
        file.statistics?.avgMedianDeviation = stats.avgMedianDeviation

        // Stretch the image
        guard let stretchedImage = file.stretchedImage else {
            print("PROCESSOR: Failed to stretch image")
            return
        }

        // Save a stretched PNG preview (lossy)
        let thumbnailWidth = 512.0
        let aspectRatio = Double(stretchedImage.height) / Double(stretchedImage.width)
        let thumbnail = stretchedImage.resize(to: CGSize(width: thumbnailWidth, height: thumbnailWidth * aspectRatio))
        guard let stretchedPreviewData = thumbnail?.pngData else {
            print("PROCESSOR: Failed to render thumbnail png")
            return
        }
        let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0] as URL
        let stretchedPreviewURL = docsURL.appendingPathComponent("\(file.id).preview.png")
        do {
            try stretchedPreviewData.write(to: stretchedPreviewURL, options: [.atomic])
        } catch {
            print("PROCESSOR: Failed to write preview image")
        }
        file.previewURL = stretchedPreviewURL

        // Perform region detection
        file.regions = NSSet(array: file.detectRegions())

        // Save the file
        do {
            try context.save()
        } catch {
            print("PROCESSOR: Failed to save context!")
        }
    }
}
