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

class ImageProcessingOperation: Operation, ObservableObject {
    var files: [File] = []
    var completion: ((CIImage) -> Void)?

    @Published var isProcessingFrames = false

    init(files: [File], completion: ((CIImage) -> Void)? = nil) {
        self.files = files
        self.completion = completion
    }

    var ciImages: [CIImage] {
        files.compactMap { file in
            guard let cgImage = file.cgImage else { return nil }
            return CIImage(cgImage: cgImage)
        }
    }

    override func main() {}
}
