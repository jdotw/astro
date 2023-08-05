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

    func setFiles(_ files: Set<File>) {
        frameBuffer.removeAll()
        alignedFrameBuffer.removeAll()
        for file in files {
            add(file.rawDataURL)
        }
    }

    func processFrames(completion: ((CIImage) -> Void)?) {
        isProcessingFrames = true
        self.completion = completion
        let firstFrame = frameBuffer.removeFirst()

        // JW DEBUG
        let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0] as URL
        let ciContext = CIContext()
        try! ciContext.writeTIFFRepresentation(of: firstFrame, to: docsURL.appendingPathComponent("reference.tiff"), format: .L16, colorSpace: CGColorSpaceCreateDeviceGray(), options: [:])
        // END JW DEBUG

        alignedFrameBuffer.append(firstFrame)
        var imageCount = 0
        for frame in frameBuffer {
            let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0] as URL
            let ciContext = CIContext()
            try! ciContext.writeTIFFRepresentation(of: frame, to: docsURL.appendingPathComponent("original-\(imageCount).tiff"), format: .L16, colorSpace: CGColorSpaceCreateDeviceGray(), options: [:])
            imageCount += 1

            let request = VNTranslationalImageRegistrationRequest(targetedCIImage: frame)
            do {
                let sequenceHandler = VNSequenceRequestHandler()
                try sequenceHandler.perform([request], on: firstFrame)
            } catch {
                print(error.localizedDescription)
            }
            alignImages(request: request, frame: frame)
        }
        imageCount = 0
        for frame in alignedFrameBuffer {
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
