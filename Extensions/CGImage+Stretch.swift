//
//  CGImage+Stretch.swift
//  Astro
//
//  Created by James Wilson on 29/7/2023.
//

import CoreGraphics
import Foundation

extension CGImage {
    var unsortedPixels: [Float]? {
        let size = CGSize(width: width, height: height)
        
        let colorSpace = CGColorSpaceCreateDeviceGray()
        
        let bitsPerComponent = 32
        let bytesPerRow = width * (bitsPerComponent / 8)
        let bitmapInfo: UInt32 = CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.none.rawValue | CGBitmapInfo.floatComponents.rawValue
        
        var pixels = [Float](repeating: 0, count: height * width)
        guard let context = CGContext(data: &pixels,
                                      width: width,
                                      height: height,
                                      bitsPerComponent: bitsPerComponent,
                                      bytesPerRow: bytesPerRow,
                                      space: colorSpace,
                                      bitmapInfo: bitmapInfo) else { return nil }
        
        context.draw(self, in: CGRect(origin: .zero, size: size))
        
        return pixels
    }

    func mtf(midtone: Float, x: Float) -> Float {
        switch x {
        case 0:
            return 0
        case midtone:
            return 0.5
        case 1:
            return 1
        default:
            return (midtone - 1) * x / ((((2 * midtone) - 1) * x) - midtone)
        }
    }
    
    var stretchedImage: CGImage? {
        guard let pixels = self.unsortedPixels else { return nil }
        var sortedFP = pixels.sorted { x, y in
            x > y
        }
        let max = sortedFP[0]
        print("MAX: ", max)
    
        for i in 0 ..< sortedFP.count {
            sortedFP[i] = sortedFP[i] / max
        }
        
        var median: Float = 0.0
        if sortedFP.count % 2 == 0 {
            median = (sortedFP[sortedFP.count / 2] + sortedFP[(sortedFP.count / 2) - 1]) / 2.0
        } else {
            median = sortedFP[(sortedFP.count - 1) / 2]
        }
        print("CALCULATED MEDIAN: ", median)
    
        var deviations = [Float](repeating: 0.0, count: sortedFP.count)
        for i in 0 ..< sortedFP.count {
            deviations[i] = abs(sortedFP[i] - median)
        }
        let avgMedDev = deviations.reduce(0, +) / Float(deviations.count)
        print("AVG MEDIAN DEVIATION: ", avgMedDev)
    
        let shadowClipConst = Float(-1.25)
        let shadowClip = median + (shadowClipConst * avgMedDev)
        print("SHADOW CLIP: ", shadowClip)
        let targetBG = Float(0.25)
        let midtone = self.mtf(midtone: targetBG, x: median - shadowClip)
        print("MIDTONE: ", midtone)
        var out = [Float](repeating: 0.0, count: sortedFP.count)
        for i in 0 ..< pixels.count {
            if pixels[i] < shadowClip {
                out[i] = 0
            } else {
                let normalised = (pixels[i] - shadowClip) / (1 - shadowClip)
                switch normalised {
                case 0:
                    out[i] = 0
                case midtone:
                    out[i] = 0.5
                case 1:
                    out[i] = 1
                default:
                    out[i] = (midtone - 1) * normalised / ((((2 * midtone) - 1) * normalised) - midtone)
                }
            }
        }
        
        let data = NSData(bytes: out, length: out.count * MemoryLayout<Float>.size)
        
        let image = CGImage(
            width: width,
            height: height,
            bitsPerComponent: 32,
            bitsPerPixel: 32,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGBitmapInfo(rawValue:
                CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.none.rawValue | CGBitmapInfo.floatComponents.rawValue),
            provider: CGDataProvider(data: data as CFData)!,
            decode: nil,
            shouldInterpolate: false,
            intent: CGColorRenderingIntent.defaultIntent
        )
        return image
    }
}
