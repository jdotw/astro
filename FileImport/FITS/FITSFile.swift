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

struct FITSFile {
    var url: URL

    // MARK: Headers

    func parseHeaders(dataStartOffset: inout UInt64) -> [String: FITSHeaderKeyword]? {
        guard let file = try? FileHandle(forReadingFrom: url)
        else {
            return nil
        }
        dataStartOffset = 0
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
                    dataStartOffset = try file.offset()
                    break
                }
            }
        } catch {
            print("Error reading block: \(error)")
            return nil
        }
        return headers
    }
    
    // MARK: Data
    
    func getImageData(fromOffset dataStartOffset: UInt64, headers: [String: FITSHeaderKeyword]) -> Data? {
        // Must return the image as 32bit Floating Point data
        guard let file = try? FileHandle(forReadingFrom: url),
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
        
        guard let bZeroString = headers["BZERO"]?.value,
              let bZero = Float(bZeroString)
        else {
            return nil
        }
        
        let signedArray = data.withUnsafeBytes { Array($0.bindMemory(to: Int16.self)) }
        let fpArray = signedArray.map { (Float(Int16(bigEndian: $0)) + bZero) / Float(UINT16_MAX) }
        let fpData = fpArray.withUnsafeBytes { Data($0) }
        
        return fpData
    }
    
    // MARK: Image
    
    func cgImage(data: Data, headers: [String: FITSHeaderKeyword]) -> CGImage? {
        guard let width = Int(headers["NAXIS1"]!.value!),
              let height = Int(headers["NAXIS2"]!.value!)
        else {
            return nil
        }
        
        let bitsPerComponent = 32
        let bitsPerPixel = 32

        let bytesPerRow = width * (abs(bitsPerPixel) / 8)
        let colorSpace = CGColorSpaceCreateDeviceGray()
        
        let bitmapInfo = CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder32Little.rawValue | CGBitmapInfo.floatComponents.rawValue)
        
        let image = CGImage(
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
            intent: CGColorRenderingIntent.defaultIntent
        )
        return image
    }
    
    var cgImage: CGImage? {
        var dataStartOffset: UInt64 = 0
        guard let headers = parseHeaders(dataStartOffset: &dataStartOffset) else {
            return nil
        }
//        var observationDate: Date!
//        if let headerDateString = headers["DATE-OBS"]?.value {
//            guard
//                let headerDate = Date(fitsDate: headerDateString)
//            else {
//                throw FITSFileImportError.invalidObservationDate
//            }
//            observationDate = headerDate
//        } else if let fileCreationDate = try? fitsFile.url.resourceValues(forKeys: [.creationDateKey]).creationDate {
//            observationDate = fileCreationDate
//        } else {
//            throw FITSFileImportError.noObservationDate
//        }
//
//        let typeString = headers["FRAME"]?.value?.lowercased() ?? "light"
//
//        guard let bookmarkData = try? url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil) else {
//            throw FITSFileImportError.noBookmark
//        }
//        guard let targetName = headers["OBJECT"]?.value else {
//            throw FITSFileImportError.noTarget
//        }
        guard let widthString = headers["NAXIS1"]?.value,
              let width = Int(widthString),
              let heightString = headers["NAXIS2"]?.value,
              let height = Int(heightString)
        else {
            return nil
        }

        // Get Data and Image
        guard let data = getImageData(fromOffset: dataStartOffset, headers: headers) else {
            return nil
        }

        // Create Image
        let bitsPerComponent = 32
        let bitsPerPixel = 32
        let bytesPerRow = width * (bitsPerPixel / 8)
        let colorSpace = CGColorSpaceCreateDeviceGray()
        let bitmapInfo = CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder32Little.rawValue | CGBitmapInfo.floatComponents.rawValue)
        let image = CGImage(
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
            intent: CGColorRenderingIntent.defaultIntent
        )
        return image

        
    }
}
