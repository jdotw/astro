//
//  FITS.swift
//  Astro
//
//  Created by James Wilson on 5/7/2023.
//

import AppKit
import CoreImage
import CoreImage.CIFilterBuiltins
import CryptoKit
import Foundation

class FITSFile {
    var url: URL?

    init?(url: URL) {
        guard url.startAccessingSecurityScopedResource() else {
            return nil
        }
        self.url = url
    }

    deinit {
        if let url = url {
            url.stopAccessingSecurityScopedResource()
        }
    }

    init(headers: [String: FITSHeaderKeyword]) {
        self.cachedHeaders = headers
    }

    private var cachedHeaders: [String: FITSHeaderKeyword]?
    var headers: [String: FITSHeaderKeyword]? {
        if let headers = cachedHeaders {
            return headers
        }
        guard let url = url else { return nil }
        var headers = [String: FITSHeaderKeyword]()
        let file = try! FileHandle(forReadingFrom: url)
        do {
            while let block = try file.readBlock() {
                let recordSize = 80
                for i in 0..<36 {
                    let record = block[i*recordSize..<(i + 1)*recordSize]
                    if let keyword = FITSHeaderKeyword(record: record) {
                        headers[keyword.name] = keyword
                    }
                }
                if headers["END"] != nil {
                    cachedDataStartOffset = try file.offset()
                    break
                }
            }
        } catch {
            print("Error reading block: \(error)")
        }
        cachedHeaders = headers
        return headers
    }

    private var cachedDataStartOffset: UInt64?
    var dataStartOffset: UInt64 {
        if let cachedDataStartOffset = cachedDataStartOffset {
            return cachedDataStartOffset
        }
        _ = headers // Getting headers should set cachedDataStartOffset
        return cachedDataStartOffset!
    }

    var data: Data? {
        guard let url = url else { return nil }
        var data = Data()
        let file = try! FileHandle(forReadingFrom: url)
        do {
            try file.seek(toOffset: dataStartOffset)
            while let block = try file.readBlock() {
                data.append(block)
            }
        } catch {
            print("Error reading block: \(error)")
        }
        return data
    }

    var type: String? {
        guard let headers = headers else { return nil }
        return headers["FRAME"]?.value!.lowercased() ?? "light"
    }

    var fileHash: String? {
        guard let url = url else { return nil }
        let file = try! FileHandle(forReadingFrom: url)
        do {
            let digest = try SHA512.hash(data: file.readToEnd()!)
            return digest.map { String(format: "%02x", $0) }.joined()
        } catch {
            return nil
        }
    }

    func convertToUnsigned(data: Data, offset: Int32) -> Data {
        let signedArray = data.withUnsafeBytes { Array($0.bindMemory(to: Int16.self)) }
        let unsigned16Array = signedArray.map { UInt16(Int32(Int16(bigEndian: $0)) + offset).bigEndian }
        let unsignedData = unsigned16Array.withUnsafeBytes { Data($0) }
        return unsignedData
    }

    func adjustBrightnessAndContrast(inputImage: CGImage, brightness: Float, contrast: Float) -> CGImage? {
        let ciContext = CIContext(options: nil)

        // Change the CGImage into a CIImage
        let ciImage = CIImage(cgImage: inputImage)

        // Set up a filter to adjust brightness and contrast
        guard let filter = CIFilter(name: "CIColorControls") else {
            return nil
        }

        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(brightness, forKey: kCIInputBrightnessKey)
        filter.setValue(contrast, forKey: kCIInputContrastKey)

        // Get the image from the filter
        guard let outputCIImage = filter.outputImage else {
            return nil
        }

        // Change the output CIImage back to a CGImage
        let outputCGImage = ciContext.createCGImage(outputCIImage, from: outputCIImage.extent)
        return outputCGImage
    }

    func adjustExposure(inputImage: CGImage, ev: Float = 1.0) -> CGImage? {
        let ciContext = CIContext()

        // Convert the CGImage to a CIImage
        let ciImage = CIImage(cgImage: inputImage)

        // Create a filter to adjust exposure
        guard let filter = CIFilter(name: "CIExposureAdjust") else {
            return nil
        }

        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(ev, forKey: kCIInputEVKey) // Increase exposure

        // Get the output image from the filter
        guard let outputCIImage = filter.outputImage else {
            return nil
        }

        // Convert the output CIImage to a CGImage
        let outputCGImage = ciContext.createCGImage(outputCIImage, from: outputCIImage.extent)
        return outputCGImage
    }

    func createHistogram(inputImage: CGImage) -> CGImage? {
        let ciContext = CIContext()

        // Convert the CGImage to a CIImage
        let ciImage = CIImage(cgImage: inputImage)

        // Create an area histogram filter
        guard let areaHistogramFilter = CIFilter(name: "CIAreaHistogram") else {
            return nil
        }

        areaHistogramFilter.setValue(ciImage, forKey: kCIInputImageKey)
        areaHistogramFilter.setValue(CIVector(cgRect: ciImage.extent), forKey: kCIInputExtentKey)
        areaHistogramFilter.setValue(256, forKey: "inputCount") // Number of bins
        areaHistogramFilter.setValue(1.0, forKey: "inputScale") // Scaling factor

        // Get the histogram data from the filter
        guard let histogramData = areaHistogramFilter.outputImage else {
            return nil
        }

        // Create a histogram display filter
        guard let histogramDisplayFilter = CIFilter(name: "CIHistogramDisplayFilter") else {
            return nil
        }

        histogramDisplayFilter.setValue(histogramData, forKey: kCIInputImageKey)
        histogramDisplayFilter.setValue(300, forKey: "inputHeight") // Height of the histogram
        histogramDisplayFilter.setValue(1.0, forKey: "inputHighLimit") // Maximum intensity
        histogramDisplayFilter.setValue(0.0, forKey: "inputLowLimit") // Minimum intensity

        // Get the output image from the filter
        guard let outputCIImage = histogramDisplayFilter.outputImage else {
            return nil
        }

        // Convert the output CIImage to a CGImage
        let outputCGImage = ciContext.createCGImage(outputCIImage, from: outputCIImage.extent)
        return outputCGImage
    }

    func image() -> CGImage? {
        guard let headers = headers,
              let data = data,
              let info = FITSCGImageInfo(headers: headers)
        else {
            return nil
        }
        let convertedData = convertToUnsigned(data: data, offset: 32768)
        let image = CGImage(
            width: info.width,
            height: info.height,
            bitsPerComponent: info.bitsPerComponent,
            bitsPerPixel: info.bitsPerPixel,
            bytesPerRow: info.bytesPerRow,
            space: info.colorSpace,
            bitmapInfo: info.bitmapInfo,
            provider: CGDataProvider(data: convertedData as CFData)!,
            decode: info.decode,
            shouldInterpolate: info.shouldInterpolate,
            intent: info.intent
        )
        return image
    }
}

enum FITSFileError: Error {
    case blockTooSmall(_: Int)
}
