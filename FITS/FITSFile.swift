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

class FITSFile: ObservableObject {
    var url: URL?
    var isAccessingScopedResource = false
    @Published var cgImage: CGImage?
    @Published var isLoading = false

    init?(url: URL) {
        self.url = url
    }

    init?(file: File) {
        var stale = false
        guard let url = try? URL(resolvingBookmarkData: file.bookmark, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &stale) else {
            return nil
        }
        self.isAccessingScopedResource = url.startAccessingSecurityScopedResource()
        self.url = url
    }

    deinit {
        if let url = url, isAccessingScopedResource {
            url.stopAccessingSecurityScopedResource()
        }
    }

    init(headers: [String: FITSHeaderKeyword]) {
        self.cachedHeaders = headers
    }

    func parseHeadersUsingFileHandle() -> [String: FITSHeaderKeyword]? {
        guard let url = url,
              let file = try? FileHandle(forReadingFrom: url)
        else {
            return nil
        }
        var headers = [String: FITSHeaderKeyword]()
        do {
            while let block = try file.readBlock() {
                let recordSize = 80
                for i in 0 ..< 36 {
                    let record = block[i * recordSize ..< (i + 1) * recordSize]
                    if let keyword = FITSHeaderKeyword(record: record) {
                        headers[keyword.name] = keyword
                    }
                }
                if headers["END"] != nil {
                    cachedDataStartOffset = try Int(file.offset())
                    break
                }
            }
        } catch {
            print("Error reading block: \(error)")
        }
        cachedHeaders = headers
        return headers
    }

    func parseHeadersUsingMemMappedData() -> [String: FITSHeaderKeyword]? {
        if let headers = cachedHeaders {
            return headers
        }
        guard let url = url else { return nil }
        var headers = [String: FITSHeaderKeyword]()

        let data = try! Data(contentsOf: url, options: .alwaysMapped)
        let chunkSize = 2880
        var stop = false
        for start in stride(from: 0, to: data.count, by: chunkSize) {
            let end = min(start + chunkSize, data.count)
            let recordSize = 80
            for start in stride(from: start, to: end, by: recordSize) {
                let end = min(start + recordSize, data.count)
                let range = start ..< end
                let record = data[range]
                if let keyword = FITSHeaderKeyword(record: record) {
                    headers[keyword.name] = keyword
                }
                if headers["END"] != nil {
                    cachedDataStartOffset = start
                    stop = true
                    break
                }
            }
            if stop {
                break
            }
        }
        return headers
    }

    private var cachedHeaders: [String: FITSHeaderKeyword]?
    var headers: [String: FITSHeaderKeyword]? {
        if let headers = cachedHeaders {
            return headers
        }
        cachedHeaders = parseHeadersUsingFileHandle()
        return cachedHeaders
    }

    private var cachedDataStartOffset: Int?
    var dataStartOffset: Int {
        if let cachedDataStartOffset = cachedDataStartOffset {
            return cachedDataStartOffset
        }
        _ = headers // Getting headers should set cachedDataStartOffset
        return cachedDataStartOffset!
    }

    var data: Data? {
        guard let url = url,
              let file = try? FileHandle(forReadingFrom: url),
              let headers = headers,
              let bitpixString = headers["BITPIX"]?.value,
              let bitpix = Int(bitpixString),
              let nAxis1String = headers["NAXIS1"]?.value,
              let nAxis1 = Int(nAxis1String),
              let nAxis2String = headers["NAXIS2"]?.value,
              let nAxis2 = Int(nAxis2String)
        else {
            return nil
        }

        let dataSize = nAxis1 * nAxis2 * (Int(bitpix) / 8)

        var data = Data(capacity: dataSize)
        do {
            try file.seek(toOffset: UInt64(dataStartOffset))
            let blockSize = 2880
            while data.count < dataSize,
                  let block = try file.readBlock(size: min(blockSize, dataSize - data.count))
            {
                data.append(block)
            }
        } catch {
            print("Error reading block: \(error)")
            return nil
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

    var observationDate: Date? {
        guard let value = headers?["DATE-OBS"]?.value else {
            return nil
        }
        return Date(fitsDate: value)
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

    var convertedData: Data? {
        guard let headers = headers,
              let bZeroString = headers["BZERO"]?.value,
              let bZero = Int32(bZeroString),
              let data = data
        else {
            return nil
        }
        let convertedData = convertToUnsigned(data: data, offset: bZero)
        return convertedData
    }

    var syncCGImage: CGImage? {
        guard let headers = headers,
              let info = FITSCGImageInfo(headers: headers),
              let convertedData = convertedData
        else {
            return nil
        }
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

    func image(completion: @escaping (CGImage?) -> Void) {
        DispatchQueue.global().async {
            let image = self.syncCGImage
            DispatchQueue.main.async {
                completion(image)
            }
        }
    }

    func loadImage() {
        if isLoading {
            return
        }
        isLoading = true
        image { image in
            self.cgImage = image
            self.isLoading = false
        }
    }

    // Core Data

    enum FITSFileImportError: Error {
        case hashFailed
        case alreadyExists
        case noHeaders
        case noObservationDate
        case noURL
        case noType
        case noBookmark
        case noTarget
        case dataConversionFailed
        case cgImageCreationFailed
    }

    func importFile(context: NSManagedObjectContext) throws -> File {
        guard let fileHash = fileHash else {
            throw FITSFileImportError.hashFailed
        }

        let sema = DispatchSemaphore(value: 0)
        var alreadyExists = false
        DispatchQueue.main.async {
            // Look up File by fileHash
            let fileReq = NSFetchRequest<File>(entityName: "File")
            fileReq.predicate = NSPredicate(format: "contentHash == %@", fileHash)
            fileReq.fetchLimit = 1
            if let _ = try? context.fetch(fileReq).first {
                alreadyExists = true
            }
            sema.signal()
        }
        sema.wait()
        guard !alreadyExists else {
            print("ALREADY EXISTS: \(fileHash)")
            throw FITSFileImportError.alreadyExists
        }
        print("DOES NOT EXIST: \(fileHash)")

        guard let headers = headers else {
            throw FITSFileImportError.noHeaders
        }
        guard let observationDate = observationDate
        else {
            throw FITSFileImportError.noObservationDate
        }
        guard let url = url else {
            throw FITSFileImportError.noURL
        }
        guard let type = type else {
            throw FITSFileImportError.noType
        }
        guard let bookmarkData = try? url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil) else {
            throw FITSFileImportError.noBookmark
        }
        guard let targetName = headers["OBJECT"]?.value else {
            throw FITSFileImportError.noTarget
        }
        guard let convertedData = convertedData else {
            throw FITSFileImportError.dataConversionFailed
        }
        guard let cgImage = syncCGImage else {
            throw FITSFileImportError.cgImageCreationFailed
        }

        let fileID = UUID().uuidString

        // Write converted (raw pixel) data to disk
        let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0] as URL
        let rawDataURL = docsURL.appendingPathComponent("\(fileID).u16")
        try! convertedData.write(to: rawDataURL, options: [.atomic])

        // Save a PNG
        let pngData = NSBitmapImageRep(cgImage: cgImage).representation(using: .png, properties: [:])!
        let previewURL = docsURL.appendingPathComponent("\(fileID).png")
        try! pngData.write(to: previewURL, options: [.atomic])

        var file: File?
        let coreDataSema = DispatchSemaphore(value: 0)
        DispatchQueue.main.async {
            // Look up File by fileHash
            // Create new file
            file = File(context: context)
            guard let file = file else {
                return
            }
            file.id = fileID
            file.timestamp = observationDate
            file.contentHash = fileHash
            file.name = url.lastPathComponent
            file.type = type
            file.url = url
            file.bookmark = bookmarkData
            file.filter = headers["FILTER"]?.value?.lowercased()
            file.rawDataURL = rawDataURL
            file.previewURL = previewURL

            // Find/Create Target
            let targetReq = NSFetchRequest<Target>(entityName: "Target")
            targetReq.predicate = NSPredicate(format: "name == %@", targetName)
            targetReq.fetchLimit = 1
            if let target = try? context.fetch(targetReq).first {
                file.target = target
            } else {
                let newTarget = Target(context: context)
                newTarget.id = UUID().uuidString
                newTarget.name = targetName
                file.target = newTarget
            }

            // Find Session by dateString
            let dateString = observationDate.sessionDateString()
            let sessionReq = NSFetchRequest<Session>(entityName: "Session")
            sessionReq.predicate = NSPredicate(format: "dateString == %@", dateString)
            sessionReq.fetchLimit = 1
            if let session = try? context.fetch(sessionReq).first {
                file.session = session
            } else {
                let newSession = Session(context: context)
                newSession.id = UUID().uuidString
                newSession.dateString = dateString
                file.session = newSession
            }

            try! context.save()

            coreDataSema.signal()
        }

        coreDataSema.wait()

        return file!
    }
}

enum FITSFileError: Error {
    case blockTooSmall(_: Int)
}
