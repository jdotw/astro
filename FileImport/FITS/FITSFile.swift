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
              let bZero = Int32(bZeroString)
        else {
            return nil
        }
        
        let signedArray = data.withUnsafeBytes { Array($0.bindMemory(to: Int16.self)) }
        let unsigned16Array = signedArray.map { UInt16(Int32(Int16(bigEndian: $0)) + bZero).bigEndian }
        let unsignedData = unsigned16Array.withUnsafeBytes { Data($0) }
        
        return unsignedData
    }
    
    // MARK: Hash
    
    var fileHash: String? {
        let file = try! FileHandle(forReadingFrom: url)
        do {
            let digest = try SHA512.hash(data: file.readToEnd()!)
            return digest.map { String(format: "%02x", $0) }.joined()
        } catch {
            return nil
        }
    }
    
    // MARK: Image
    
    func cgImage(data: Data, headers: [String: FITSHeaderKeyword]) -> CGImage? {
        guard let width = Int(headers["NAXIS1"]!.value!),
              let height = Int(headers["NAXIS2"]!.value!),
              let bitsPerComponent = Int(headers["BITPIX"]!.value!),
              let bitsPerPixel = Int(headers["BITPIX"]!.value!)
        else {
            return nil
        }
        let bytesPerRow = width * (abs(bitsPerPixel) / 8)
        let colorSpace = CGColorSpaceCreateDeviceGray()
        
        var bitmapInfo = CGBitmapInfo()
        switch bitsPerPixel {
        case 16:
            bitmapInfo = CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder16Big.rawValue)
        case -32:
            bitmapInfo = CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder32Big.rawValue | CGBitmapInfo.floatComponents.rawValue)
        default:
            return nil
        }
        
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
