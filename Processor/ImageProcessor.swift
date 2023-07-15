//
//  ImageProcessor.swift
//  Astro
//
//  Created by James Wilson on 15/7/2023.
//

import CoreData
import CoreGraphics
import CoreImage
import Foundation
import SwiftUI
import Vision

class ImageProcessor: ObservableObject {
    var frameBuffer: [CIImage] = []
    var alignedFrameBuffer: [CIImage] = []
    var completion: ((CIImage) -> Void)?
    @Published var isProcessingFrames = false

    var frameCount: Int {
        return frameBuffer.count
    }

    func add(_ frame: CIImage) {
        if isProcessingFrames {
            return
        }
        frameBuffer.append(frame)
    }

    func add(_ url: URL) {
        if isProcessingFrames {
            return
        }

        if let ciImage = CIImage(contentsOf: url) {
            frameBuffer.append(ciImage)
        } else {
            print("Failed to load image")
        }
    }

    func setFilesIDs(_ fileIDs: Set<File.ID>, context: NSManagedObjectContext) {
        frameBuffer.removeAll()
        alignedFrameBuffer.removeAll()
        let req = File.fetchRequest()
        for fileID in fileIDs {
            req.predicate = NSPredicate(format: "id == %@", fileID as CVarArg)
            if let file = try? context.fetch(req).first {
                add(file.rawDataURL)
            }
        }
    }

    func processFrames(completion: ((CIImage) -> Void)?) {
        // 1
        isProcessingFrames = true
        self.completion = completion
        // 2
        let firstFrame = frameBuffer.removeFirst()

        // JW DEBUG
        let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0] as URL
        let ciContext = CIContext()
        try! ciContext.writeTIFFRepresentation(of: firstFrame, to: docsURL.appendingPathComponent("reference.tiff"), format: .L16, colorSpace: CGColorSpaceCreateDeviceGray(), options: [:])
        // END JW DEBUG

        alignedFrameBuffer.append(firstFrame)
        // 3
        var imageCount = 0
        for frame in frameBuffer {
            let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0] as URL
            let ciContext = CIContext()
            try! ciContext.writeTIFFRepresentation(of: frame, to: docsURL.appendingPathComponent("original-\(imageCount).tiff"), format: .L16, colorSpace: CGColorSpaceCreateDeviceGray(), options: [:])
            imageCount += 1

            // 4
            let request = VNTranslationalImageRegistrationRequest(targetedCIImage: frame)

            do {
                // 5
                let sequenceHandler = VNSequenceRequestHandler()
                // 6
                try sequenceHandler.perform([request], on: firstFrame)
            } catch {
                print(error.localizedDescription)
            }
            // 7
            alignImages(request: request, frame: frame)
        }
        imageCount = 0
        for frame in alignedFrameBuffer {
            // 8
            let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0] as URL
            let ciContext = CIContext()
            try! ciContext.writeTIFFRepresentation(of: frame, to: docsURL.appendingPathComponent("aligned-\(imageCount).tiff"), format: .L16, colorSpace: CGColorSpaceCreateDeviceGray(), options: [:])
            imageCount += 1
        }

        combineFrames()
    }

    func alignImages(request: VNRequest, frame: CIImage) {
        // 1
        guard
            let results = request.results as? [VNImageTranslationAlignmentObservation],
            let result = results.first
        else {
            print("ALIGNMENT FAILED")
            return
        }
        print("ALIGNMENT: \(result)")
        // 2
        let alignedFrame = frame.transformed(by: result.alignmentTransform)
        // 3
        alignedFrameBuffer.append(alignedFrame)
    }

    func combineFrames() {
        // 1
        var finalImage = alignedFrameBuffer.removeFirst()
        // 2
        let filter = AverageStackingFilter()
        // 3
        for (i, image) in alignedFrameBuffer.enumerated() {
            // 4
            filter.inputCurrentStack = finalImage
            filter.inputNewImage = image
            filter.inputStackCount = Double(i + 1)
            // 5
            finalImage = filter.outputImage()!
        }
        // 6
        cleanup(image: finalImage)
    }

    func cleanup(image: CIImage) {
        frameBuffer = []
        alignedFrameBuffer = []
        isProcessingFrames = false
        if let completion = completion {
            DispatchQueue.main.async {
                completion(image)
            }
        }
        let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0] as URL
        let ciContext = CIContext()
        try! ciContext.writeTIFFRepresentation(of: image, to: docsURL.appendingPathComponent("stacked.tiff"), format: .L16, colorSpace: CGColorSpaceCreateDeviceGray(), options: [:])

        completion = nil
    }
}
