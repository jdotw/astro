//
//  CGImage+Stretch.swift
//  Astro
//
//  Created by James Wilson on 29/7/2023.
//

import CoreGraphics
import Foundation

struct StretchParameters {
    var shadowClip: Float
    var midtone: Float
}

extension CGImage {
    func unsortedPixels(ofWidth width: Int, height: Int) -> [Float]? {
        var pixels = [Float](repeating: 0, count: width * height)
        guard let context = CGContext(data: &pixels,
                                      width: width,
                                      height: height,
                                      bitsPerComponent: MemoryLayout<Float>.size * 8,
                                      bytesPerRow: MemoryLayout<Float>.size * width,
                                      space: colorSpace ?? CGColorSpaceCreateDeviceGray(),
                                      bitmapInfo: bitmapInfo.rawValue) else { return nil }
        context.draw(self, in: CGRect(origin: .zero, size: CGSize(width: width, height: height)))
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
    
    var stretchParameters: StretchParameters? {
        print("GETTING DOWN-SIZED PIXELS")
        let subframeWidth = width / 4
        let subframeHeight = height / 4
        guard var pixels = self.unsortedPixels(ofWidth: subframeWidth, height: subframeHeight)?.sorted()
        else { return nil }
        print("SORTED")
        guard let max = pixels.last else { return nil }
        print("MAX: ", max)
        
        for i in 0 ..< pixels.count {
            pixels[i] = pixels[i] / max
        }
        
        var median: Float = 0.0
        if pixels.count % 2 == 0 {
            median = (pixels[pixels.count / 2] + pixels[(pixels.count / 2) - 1]) / 2.0
        } else {
            median = pixels[(pixels.count - 1) / 2]
        }
        print("CALCULATED MEDIAN: ", median)
        
        var deviations = [Float](repeating: 0.0, count: pixels.count)
        for i in 0 ..< pixels.count {
            deviations[i] = abs(pixels[i] - median)
        }
        let avgMedDev = deviations.reduce(0, +) / Float(deviations.count)
        print("AVG MEDIAN DEVIATION: ", avgMedDev)
        
        let shadowClipConst = Float(-1.25)
        let shadowClip = median + (shadowClipConst * avgMedDev)
        print("SHADOW CLIP: ", shadowClip)
        let targetBG = Float(0.25)
        let midtone = self.mtf(midtone: targetBG, x: median - shadowClip)
        print("MIDTONE: ", midtone)

        return StretchParameters(shadowClip: shadowClip, midtone: midtone)
    }
    
    var stretchedImage: CGImage? {
        print("START")
        print("LOADED UNSORTED")
        print("SORTING...")
        guard let params = stretchParameters else { return nil }

        guard let pixels = self.unsortedPixels(ofWidth: width, height: height) else { return nil }
        var out = [Float](repeating: 0.0, count: pixels.count)
        for i in 0 ..< pixels.count {
            if pixels[i] < params.shadowClip {
                out[i] = 0
            } else {
                let normalised = (pixels[i] - params.shadowClip) / (1 - params.shadowClip)
                switch normalised {
                case 0:
                    out[i] = 0
                case params.midtone:
                    out[i] = 0.5
                case 1:
                    out[i] = 1
                default:
                    out[i] = (params.midtone - 1) * normalised / ((((2 * params.midtone) - 1) * normalised) - params.midtone)
                }
            }
        }
            
        let data = NSData(bytes: out, length: out.count * MemoryLayout<Float>.size)
            
        let image = CGImage(
            width: self.width,
            height: self.height,
            bitsPerComponent: MemoryLayout<Float>.size * 8,
            bitsPerPixel: MemoryLayout<Float>.size * 8,
            bytesPerRow: self.width * 4,
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
