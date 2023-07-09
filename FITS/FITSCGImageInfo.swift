//
//  FITSCGImageInfo.swift
//  Astro
//
//  Created by James Wilson on 9/7/2023.
//

import CoreImage
import Foundation

struct FITSCGImageInfo {
    var width: Int
    var height: Int
    var bitsPerComponent: Int
    var bitsPerPixel: Int
    var bytesPerRow: Int
    var colorSpace: CGColorSpace
    var bitmapInfo: CGBitmapInfo
    var decode: UnsafePointer<CGFloat>?
    var shouldInterpolate: Bool
    var intent: CGColorRenderingIntent

    init?(headers: [String: FITSHeaderKeyword]) {
        guard let width = Int(headers["NAXIS1"]!.value!),
              let height = Int(headers["NAXIS2"]!.value!),
              let bitsPerComponent = Int(headers["BITPIX"]!.value!),
              let bitsPerPixel = Int(headers["BITPIX"]!.value!)
        else {
            return nil
        }
        self.width = width
        self.height = height
        self.bitsPerComponent = abs(bitsPerComponent)
        self.bitsPerPixel = abs(bitsPerPixel)
        self.bytesPerRow = width * (self.bitsPerPixel / 8)
        self.colorSpace = CGColorSpaceCreateDeviceGray()
        switch bitsPerPixel {
        case 16:
            self.bitmapInfo = CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder16Big.rawValue)
        case -32:
            self.bitmapInfo = CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder32Big.rawValue | CGBitmapInfo.floatComponents.rawValue)
        default:
            return nil
        }
        self.decode = nil
        self.shouldInterpolate = false
        self.intent = CGColorRenderingIntent.defaultIntent
    }
}
