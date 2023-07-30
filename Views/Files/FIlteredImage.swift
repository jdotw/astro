//
//  FIlteredImage.swift
//  Astro
//
//  Created by James Wilson on 23/7/2023.
//

import Accelerate
import Foundation
import SwiftUI

struct FilteredImage: View {
    var file: File

    var exposureValue: Double
    var gammaValue: Double

    var toneCurve1: Double
    var toneCurve2: Double
    var toneCurve3: Double
    var toneCurve4: Double
    var toneCurve5: Double

    var applyToneCurve: Bool

    @State private var image: NSImage?
    @State private var unstretchedImage: CGImage!
    @State private var stretchedImage: CGImage!

    @Binding var histogramImage: NSImage

    func loadImage() {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let data = try? Data(contentsOf: file.rawDataURL) else { return }
            let width = 3326
            let height = 2504
            let bitsPerComponent = 32
            let bitsPerPixel = 32
            let bytesPerRow = width * (abs(bitsPerPixel) / 8)
            let colorSpace = CGColorSpaceCreateDeviceGray()
            let bitmapInfo = CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder32Little.rawValue | CGBitmapInfo.floatComponents.rawValue)
            unstretchedImage = CGImage(
                width: width,
                height: height,
                bitsPerComponent: bitsPerComponent,
                bitsPerPixel: bitsPerPixel,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: bitmapInfo,
                provider: CGDataProvider(data: data as CFData)!,
                decode: nil,
                shouldInterpolate: false,
                intent: CGColorRenderingIntent.defaultIntent)
            stretchedImage = unstretchedImage.stretchedImage
            DispatchQueue.main.async {
                image = NSImage(cgImage: stretchedImage, size: NSZeroSize)
                applyFilters()
            }
        }
    }

    func applyExposureFilter(inputImage: CIImage) -> CIImage? {
        guard let filter = CIFilter(name: "CIExposureAdjust") else {
            return nil
        }
        filter.setValue(inputImage, forKey: kCIInputImageKey)
        filter.setValue(exposureValue, forKey: kCIInputEVKey) // Increase exposure
        return filter.outputImage
    }

    func applyGammaFilter(inputImage: CIImage) -> CIImage? {
        guard let filter = CIFilter(name: "CIGammaAdjust") else {
            return nil
        }
        filter.setValue(inputImage, forKey: kCIInputImageKey)
        filter.setValue(gammaValue, forKey: "inputPower") // Increase exposure
        return filter.outputImage
    }

    func applyToneCurveAdjustment(inputImage: CIImage) -> CIImage? {
        guard let filter = CIFilter(name: "CIToneCurve") else {
            return nil
        }
        filter.setValue(inputImage, forKey: kCIInputImageKey)
        filter.setValue(CIVector(x: 0.0, y: toneCurve1), forKey: "inputPoint0")
        filter.setValue(CIVector(x: 0.25, y: toneCurve2), forKey: "inputPoint1")
        filter.setValue(CIVector(x: 0.5, y: toneCurve3), forKey: "inputPoint2")
        filter.setValue(CIVector(x: 0.75, y: toneCurve4), forKey: "inputPoint3")
        filter.setValue(CIVector(x: 1.0, y: toneCurve5), forKey: "inputPoint4")
        return filter.outputImage
    }

    func applyFilters() {
        let inputImage = CIImage(cgImage: stretchedImage)
        guard let gammaAdjustedImage = applyGammaFilter(inputImage: inputImage) else {
            return
        }
        guard let exposureAdjustedImage = applyExposureFilter(inputImage: gammaAdjustedImage) else {
            return
        }
        var toneCurveAdjustedImage: CIImage!
        if applyToneCurve {
            guard let result = applyToneCurveAdjustment(inputImage: exposureAdjustedImage) else {
                return
            }
            toneCurveAdjustedImage = result
        } else {
            toneCurveAdjustedImage = exposureAdjustedImage
        }

        let imageRep = NSCIImageRep(ciImage: toneCurveAdjustedImage)
        let nsImage = NSImage(size: imageRep.size)
        nsImage.addRepresentation(imageRep)
        image = nsImage
        generateHistogram(inputImage: toneCurveAdjustedImage)
    }

    func generateHistogram(inputImage: CIImage) {
        // Create an area histogram filter
        guard let areaHistogramFilter = CIFilter(name: "CIAreaHistogram") else {
            return
        }

        areaHistogramFilter.setValue(inputImage, forKey: kCIInputImageKey)
        areaHistogramFilter.setValue(CIVector(cgRect: inputImage.extent), forKey: kCIInputExtentKey)
        areaHistogramFilter.setValue(256, forKey: "inputCount") // Number of bins
        areaHistogramFilter.setValue(1.0, forKey: "inputScale") // Scaling factor

        // Get the histogram data from the filter
        guard let histogramData = areaHistogramFilter.outputImage else {
            return
        }

        // Create a histogram display filter
        guard let histogramDisplayFilter = CIFilter(name: "CIHistogramDisplayFilter") else {
            return
        }

        histogramDisplayFilter.setValue(histogramData, forKey: kCIInputImageKey)
        histogramDisplayFilter.setValue(300, forKey: "inputHeight") // Height of the histogram
        histogramDisplayFilter.setValue(1.0, forKey: "inputHighLimit") // Maximum intensity
        histogramDisplayFilter.setValue(0.0, forKey: "inputLowLimit") // Minimum intensity

        // Get the output image from the filter
        guard let outputCIImage = histogramDisplayFilter.outputImage else {
            return
        }

        // Convert the output CIImage to a CGImage
        let imageRep = NSCIImageRep(ciImage: outputCIImage)
        let nsImage = NSImage(size: imageRep.size)
        nsImage.addRepresentation(imageRep)
        histogramImage = nsImage
    }

    var body: some View {
        VStack {
            Image(nsImage: image ?? NSImage())
                .resizable()
                .scaledToFit()
                .padding()
        }
        .onChange(of: exposureValue) {
            applyFilters()
        }
        .onChange(of: gammaValue) {
            applyFilters()
        }
        .onChange(of: toneCurve1) {
            applyFilters()
        }
        .onChange(of: toneCurve2) {
            applyFilters()
        }
        .onChange(of: toneCurve3) {
            applyFilters()
        }
        .onChange(of: toneCurve4) {
            applyFilters()
        }
        .onChange(of: toneCurve5) {
            applyFilters()
        }
        .onChange(of: applyToneCurve) {
            applyFilters()
        }
        .task {
            loadImage()
        }
    }
}
