//
//  FIlteredImage.swift
//  Astro
//
//  Created by James Wilson on 23/7/2023.
//

import Accelerate
import Foundation
import SwiftUI

let cs = CGColorSpaceCreateDeviceGray()

var format = vImage_CGImageFormat(
    bitsPerComponent: 16,
    bitsPerPixel: 16,
    colorSpace: Unmanaged.passRetained(cs),
    bitmapInfo: CGBitmapInfo(
        rawValue: CGImageAlphaInfo.none.rawValue),
    version: 0,
    decode: nil,
    renderingIntent: .defaultIntent)

struct FilteredImage: View {
    var file: File
    var exposureValue: Double = 4.0
    var gammaValue: Double = 0.0

    var toneCurve1: Double = 0.0
    var toneCurve2: Double = 0.5
    var toneCurve3: Double = 0.9
    var toneCurve4: Double = 1.0
    var toneCurve5: Double = 1.2

    var applyToneCurve: Bool = true

    @State private var image: NSImage?
    @State private var inputImage: CIImage?

    @Binding var histogramImage: NSImage

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

    func applyVImageHistogramEqualization(inputImage: CIImage) -> CIImage? {
        let imageRef = CIContext().createCGImage(
            inputImage,
            from: inputImage.extent)!

        var imageBuffer = vImage_Buffer()

        vImageBuffer_InitWithCGImage(
            &imageBuffer,
            &format,
            nil,
            imageRef,
            UInt32(kvImageNoFlags))

        let pixelBuffer = malloc(imageRef.bytesPerRow * imageRef.height)

        var outBuffer = vImage_Buffer(
            data: pixelBuffer,
            height: UInt(imageRef.height),
            width: UInt(imageRef.width),
            rowBytes: imageRef.bytesPerRow)

        vImageEqualization_ARGB8888(
            &imageBuffer,
            &outBuffer,
            UInt32(kvImageNoFlags))

        let outImage = CIImage(fromvImageBuffer: outBuffer)

        free(imageBuffer.data)
        free(pixelBuffer)

        return outImage
    }

    func applyFilters() {
        if inputImage == nil {
            print("URL: ", file.rawDataURL)
            inputImage = CIImage(contentsOf: file.rawDataURL)
        }
        guard let inputImage = inputImage else {
            return
        }

        // MEDIAN TEST
        let ciContext = CIContext()
        let cgImage = ciContext.createCGImage(inputImage, from: inputImage.extent, format: CIFormat.Lf, colorSpace: CGColorSpaceCreateDeviceGray())!
        try! cgImage.tiffData?.write(to: URL(fileURLWithPath: "/Users/jwilson/Downloads/input2.tiff"))
        let stretchedImage = CIImage(cgImage: cgImage.stretchedImage!)

        // END MEDIAN TEST

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

        let acceleratedImage = applyVImageHistogramEqualization(inputImage: inputImage)!

        let imageRep = NSCIImageRep(ciImage: stretchedImage)
        let nsImage = NSImage(size: imageRep.size)
        nsImage.addRepresentation(imageRep)
        image = nsImage

        generateHistogram(inputImage: stretchedImage)
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
            applyFilters()
        }
    }
}

extension CIImage {
    convenience init?(fromvImageBuffer: vImage_Buffer) {
        var mutableBuffer = fromvImageBuffer
        var error = vImage_Error()

        let cgImage = vImageCreateCGImageFromBuffer(
            &mutableBuffer,
            &format,
            nil,
            nil,
            UInt32(kvImageNoFlags),
            &error)!

        self.init(cgImage: cgImage.takeRetainedValue())
    }
}
