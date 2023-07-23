//
//  FIlteredImage.swift
//  Astro
//
//  Created by James Wilson on 23/7/2023.
//

import Foundation
import SwiftUI

struct FilteredImage: View {
    var file: File
    var exposureValue: Double = 4.0

    @State private var image: NSImage?
    @State private var inputImage: CIImage?

    func applyFilters() {
        if inputImage == nil {
            inputImage = CIImage(contentsOf: file.rawDataURL)
        }
        guard let inputImage = inputImage else {
            return
        }

        guard let filter = CIFilter(name: "CIExposureAdjust") else {
            return
        }
        filter.setValue(inputImage, forKey: kCIInputImageKey)
        filter.setValue(exposureValue, forKey: kCIInputEVKey) // Increase exposure

        guard let outputCIImage = filter.outputImage else {
            return
        }

        let imageRep = NSCIImageRep(ciImage: outputCIImage)
        let nsImage = NSImage(size: imageRep.size)
        nsImage.addRepresentation(imageRep)
        image = nsImage
    }

    var body: some View {
        VStack {
            Image(nsImage: image ?? NSImage())
                .resizable()
                .scaledToFit()
                .padding()
            Text("Exposure: \(exposureValue, specifier: "%.2f")")
                .padding()
        }
        .onChange(of: exposureValue) {
            applyFilters()
        }
        .task {
            applyFilters()
        }
    }
}
