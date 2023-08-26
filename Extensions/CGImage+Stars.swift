//
//  CGImage+Stars.swift
//  Astro
//
//  Created by James Wilson on 25/8/2023.
//

import CoreGraphics
import CoreImage
import Foundation

private let LIT_PIXEL = UInt8(255)
private let SEEN_PIXEL = UInt8(20)
private let DARK_PIXEL = UInt8(0)
private let ERASED_PIXEL = UInt8(1)

extension CGImage {
    var starRects: [NSRect] {
        return starRects()
    }

    func starRects(minimumSize: CGSize = CGSize(width: 3.0, height: 3.0)) -> [NSRect] {
        // Get image stats (median, etc)
        guard let stats = statistics else { return [] }
        
        // Binarize using the median
        guard let filter = CIFilter(name: "CIColorThreshold") else {
            return []
        }
        filter.setValue(CIImage(cgImage: self), forKey: kCIInputImageKey)
        let calculatedThreshold = stats.median - (2.0 * stats.avgMedianDeviation)
        if calculatedThreshold > 0.0 {
            // Calculated a non-zero threshold using median and avgMedianDeviation
            filter.setValue(CGFloat(calculatedThreshold), forKey: "inputThreshold")
        } else {
            // Image is so dark that the calculated threshold is at or below 0.0
            // Use just the avgMedianDeviation in this case
            filter.setValue(CGFloat(stats.avgMedianDeviation), forKey: "inputThreshold")
        }
        guard let binaryImage = filter.outputImage else { return [] }
        
        // Render binarized image to an 8bit greyscale image (0 or 255)
        let context = CIContext(options: [.outputColorSpace: CGColorSpaceCreateDeviceGray()])
        guard let binaryCGImage = context.createCGImage(binaryImage, from: binaryImage.extent) else { return [] }
        var pixels = [UInt8](repeating: 0, count: width * height)
        let bitmapInfo = CGBitmapInfo(rawValue: CGBitmapInfo.byteOrderDefault.rawValue)
        guard let context = CGContext(data: &pixels,
                                      width: width,
                                      height: height,
                                      bitsPerComponent: MemoryLayout<UInt8>.size * 8,
                                      bytesPerRow: MemoryLayout<UInt8>.size * width,
                                      space: colorSpace ?? CGColorSpaceCreateDeviceGray(),
                                      bitmapInfo: bitmapInfo.rawValue) else { return [] }
        context.draw(binaryCGImage, in: CGRect(origin: .zero, size: CGSize(width: width, height: height)))

        return self.starRects(inPixels: &pixels, minimumSize: minimumSize)
    }
    
    func starRects(inPixels pixels: inout [UInt8], minimumSize: CGSize = CGSize(width: 3.0, height: 3.0)) -> [NSRect] {
        // Loop through every pixel in the image
        var rects = [NSRect]()
        for y in 0 ..< height {
            for x in 0 ..< width {
                let pixel = pixel(at: CGPoint(x: x, y: y), in: pixels)
                if pixel == LIT_PIXEL {
                    var rect = CGRect(x: x, y: y, width: 1, height: 1)
                    self.markPixelAsSeen(at: rect.origin, in: &pixels)
                    while true {
                        if let expandedRect = contiguousPixels(borderingRect: rect, in: &pixels) {
                            rect = expandedRect
                            continue
                        }
                        break
                    }
                    if rect.width >= minimumSize.width, rect.height >= minimumSize.height {
                        rects.append(rect)
                    }
                    self.erasePixels(inRect: rect, in: &pixels)
                }
            }
        }
        
        return rects
    }
    
    func contiguousPixels(borderingRect rect: NSRect, in pixels: inout [UInt8]) -> NSRect? {
        let originalRect = rect
        var rect = rect

        // Left side of the box, iterate through vertical
        if rect.origin.x > 0 {
            var widthDelta = 0.0
            for y in Int(rect.minY) ..< Int(rect.maxY) {
                let insidePoint = CGPoint(x: rect.origin.x, y: CGFloat(y))
                let insidePixel = self.pixel(at: insidePoint, in: pixels)
                if insidePixel == SEEN_PIXEL {
                    var candidates = [CGPoint(x: rect.origin.x - 1, y: CGFloat(y))]
                    if (y - 1) >= Int(rect.minY) {
                        candidates.append(CGPoint(x: rect.origin.x - 1, y: CGFloat(y - 1)))
                    }
                    if (y + 1) < Int(rect.maxY) {
                        candidates.append(CGPoint(x: rect.origin.x - 1, y: CGFloat(y + 1)))
                    }
                    for outsidePoint in candidates {
                        let outsidePixel = self.pixel(at: outsidePoint, in: pixels)
                        if outsidePixel == LIT_PIXEL {
                            // CONTIGUOUS PIXELS!
                            self.markPixelAsSeen(at: outsidePoint, in: &pixels)
                            widthDelta = 1
                        }
                    }
                }
            }
            rect.origin.x -= widthDelta
            rect.size.width += widthDelta
        }
        
        // Right side of the box, iterate through vertical
        if Int(rect.maxX) < width {
            var widthDelta = 0.0
            for y in Int(rect.minY) ..< Int(rect.maxY) {
                let insidePoint = CGPoint(x: rect.maxX - 1, y: CGFloat(y))
                let insidePixel = self.pixel(at: insidePoint, in: pixels)
                if insidePixel == SEEN_PIXEL {
                    var candidates = [CGPoint(x: rect.maxX, y: CGFloat(y))]
                    if (y - 1) >= Int(rect.minY) {
                        candidates.append(CGPoint(x: rect.maxX, y: CGFloat(y - 1)))
                    }
                    if (y + 1) < Int(rect.maxY) {
                        candidates.append(CGPoint(x: rect.maxX, y: CGFloat(y + 1)))
                    }
                    for outsidePoint in candidates {
                        let outsidePixel = self.pixel(at: outsidePoint, in: pixels)
                        if outsidePixel == LIT_PIXEL {
                            // CONTIGUOUS PIXELS!
                            self.markPixelAsSeen(at: outsidePoint, in: &pixels)
                            widthDelta = 1
                        }
                    }
                }
            }
            rect.size.width += widthDelta
        }

        // Bottom of the box, iterate through horizontal
        if Int(rect.maxY) < height {
            var heightDelta = 0.0
            var foundDiagonalLeft = false
            var foundDiagonalRight = false
            for x in Int(rect.minX) ..< Int(rect.maxX) {
                let insidePoint = CGPoint(x: x, y: Int(rect.maxY - 1))
                let insidePixel = self.pixel(at: insidePoint, in: pixels)
                if insidePixel == SEEN_PIXEL {
                    // CONTIGUOUS PIXELS!
                    var candidates = [CGPoint(x: x, y: Int(rect.maxY))]
                    if (x - 1) >= 0 {
                        candidates.append(CGPoint(x: x - 1, y: Int(rect.maxY)))
                    }
                    if (x + 1) < width {
                        candidates.append(CGPoint(x: x + 1, y: Int(rect.maxY)))
                    }
                    for outsidePoint in candidates {
                        let outsidePixel = self.pixel(at: outsidePoint, in: pixels)
                        if outsidePixel == LIT_PIXEL {
                            // CONTIGUOUS PIXELS!
                            self.markPixelAsSeen(at: outsidePoint, in: &pixels)
                            if Int(outsidePoint.x) < Int(rect.minX) {
                                foundDiagonalLeft = true
                            } else if Int(outsidePoint.x) >= Int(rect.maxX) {
                                foundDiagonalRight = true
                            }
                            heightDelta = 1
                        }
                    }
                }
            }
            rect.size.height += heightDelta
            if foundDiagonalLeft {
                rect.origin.x -= 1
                rect.size.width += 1
            }
            if foundDiagonalRight {
                rect.size.width += 1
            }
        }
        
        if rect != originalRect {
            return rect
        } else {
            return nil
        }
    }
    
    func pixel(at point: CGPoint, in pixels: [UInt8]) -> UInt8 {
        let i = Int(point.x) + (Int(point.y) * width)
        return pixels[i]
    }
    
    func markPixelAsSeen(at point: CGPoint, in pixels: inout [UInt8]) {
        let i = Int(point.x) + (Int(point.y) * width)
        pixels[i] = SEEN_PIXEL
    }
    
    func erasePixels(inRect rect: CGRect, in pixels: inout [UInt8]) {
        for y in Int(rect.minY) ..< Int(rect.maxY) {
            for x in Int(rect.minX) ..< Int(rect.maxX) {
                let i = x + (y * width)
                pixels[i] = ERASED_PIXEL
            }
        }
    }
}
