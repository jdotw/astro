//
//  FITS.swift
//  Astro
//
//  Created by James Wilson on 5/7/2023.
//

import AppKit
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
    
    func image() -> CGImage? {
        guard let headers = headers,
              let data = data,
              let info = FITSCGImageInfo(headers: headers)
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
            provider: CGDataProvider(data: data as CFData)!,
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
