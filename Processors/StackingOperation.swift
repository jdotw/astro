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

class StackingOperation: ImageProcessingOperation {
    override func main() {
        isProcessingFrames = true
        var frames = ciImages
        var stackedFrame = frames.removeFirst()
        let filter = AverageStackingFilter()
        for (i, image) in frames.enumerated() {
            filter.inputCurrentStack = stackedFrame
            filter.inputNewImage = image
            filter.inputStackCount = Double(i + 1)
            stackedFrame = filter.outputImage()!
        }
        completion?(stackedFrame)
        isProcessingFrames = false
    }
}
