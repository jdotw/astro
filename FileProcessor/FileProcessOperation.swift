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

    init(fileObjectID: NSManagedObjectID) {
        self.fileObjectID = fileObjectID
    }

    override func main() {
        let waitSemaphore = DispatchSemaphore(value: 0)
        PersistenceController.shared.container.performBackgroundTask { context in
            // Retrieve file
            defer { waitSemaphore.signal() }
            guard let file = context.object(with: self.fileObjectID) as? File else {
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
            guard let docsURL = URL.documentsDirectory else {
                print("PROCESSOR: Failed to get docs directory")
                return
            }
            let stretchedPreviewURL = docsURL.appendingPathComponent("\(file.uuid).preview.png")
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
                print("PROCESSOR: Failed to save context! - ", error)
            }
        }
        waitSemaphore.wait()
    }
}
