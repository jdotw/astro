//
//  File+CoreDataClass.swift
//
//
//  Created by James Wilson on 13/7/2023.
//
//  This file was NOT automatically generated and can be edited
//  We had to do this because CoreData is so bad.
//

import CoreData
import CoreGraphics
import CoreImage
import Foundation

@objc(File)
public class File: NSManagedObject {}

public enum FileType: String, CaseIterable, Identifiable {
    public var id: Self { self }
    case unknown
    case light
    case flat
    case dark
    case bias
}

public extension File {
    @nonobjc class func fetchRequest() -> NSFetchRequest<File> {
        return NSFetchRequest<File>(entityName: "File")
    }

    @NSManaged var uuid: UUID
    @NSManaged var bookmark: Data
    @NSManaged var contentHash: String
    @NSManaged var name: String
    @NSManaged var timestamp: Date
    @NSManaged var typeRawValue: String
    @NSManaged var url: URL // Original Source URL
    @NSManaged var fitsURL: URL // The FITS file as-imported
    @NSManaged var rawDataURL: URL // The 32bit fp values
    @NSManaged var previewURL: URL? // Downsized and stretched PNG
    @NSManaged var session: Session?
    @NSManaged var target: Target?
    @NSManaged var filter: Filter
    @NSManaged var rejected: Bool
    @NSManaged var width: Int32
    @NSManaged var height: Int32

    @NSManaged var statistics: FileStatistics?
    @NSManaged var regions: NSSet?
    @NSManaged var metadata: NSSet?

    @NSManaged var calibrationSession: Session?

    var type: FileType {
        get {
            FileType(rawValue: self.typeRawValue) ?? .unknown
        }
        set {
            self.typeRawValue = newValue.rawValue
        }
    }

    func type(forHeaderValue value: String) -> FileType {
        switch value {
        case "light":
            return .light
        case "dark":
            return .dark
        case "bias":
            return .bias
        case "flat":
            return .flat
        default:
            return .unknown
        }
    }
}

extension File: Identifiable {
    public var id: URL {
        objectID.uriRepresentation()
    }
}

struct ImageStatistics {
    var max: Float
    var median: Float
    var avgMedianDeviation: Float
}

struct StretchParameters {
    var shadowClip: Float
    var midtone: Float
}

extension File {
    var cgImage: CGImage? {
        guard let data = try? Data(contentsOf: rawDataURL) else { return nil }
        let width = Int(width)
        let height = Int(height)
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

    func unsortedPixels() -> [Float]? {
        return self.unsortedPixels(size: CGSize(width: Int(self.width), height: Int(self.height)))
    }

    func unsortedPixels(size: CGSize) -> [Float]? {
        guard let cgImage = cgImage else { return nil }
        var pixels = [Float](repeating: 0, count: Int(width) * Int(self.height))
        let bitmapInfo = CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder32Little.rawValue | CGBitmapInfo.floatComponents.rawValue)
        guard let context = CGContext(data: &pixels,
                                      width: Int(width),
                                      height: Int(height),
                                      bitsPerComponent: MemoryLayout<Float>.size * 8,
                                      bytesPerRow: MemoryLayout<Float>.size * Int(width),
                                      space: CGColorSpaceCreateDeviceGray(),
                                      bitmapInfo: bitmapInfo.rawValue) else { return nil }
        context.draw(cgImage, in: CGRect(origin: .zero, size: CGSize(width: Int(self.width), height: Int(self.height))))
        return pixels
    }

    func getStatistics() -> ImageStatistics? {
        print("GETTING DOWN-SIZED PIXELS")
        let subframeWidth = Int(self.width) / 4
        let subframeHeight = Int(self.height) / 4
        guard var pixels = unsortedPixels(size: CGSize(width: subframeWidth, height: subframeHeight))?.sorted()
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

        return ImageStatistics(max: max, median: median, avgMedianDeviation: avgMedDev)
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
        guard let statistics = self.statistics else { return nil }

        print("STORED MEDIAN: ", statistics.median)
        print("STORED AVG MEDIAN DEVIATION: ", statistics.avgMedianDeviation)

        let shadowClipConst = Float(-1.25)
        let shadowClip = statistics.median + (shadowClipConst * statistics.avgMedianDeviation)
        print("SHADOW CLIP: ", shadowClip)
        let targetBG = Float(0.25)
        let midtone = self.mtf(midtone: targetBG, x: statistics.median - shadowClip)
        print("MIDTONE: ", midtone)

        let params = StretchParameters(shadowClip: shadowClip, midtone: midtone)

        guard let pixels = self.unsortedPixels() else { return nil }
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
            width: Int(width),
            height: Int(height),
            bitsPerComponent: MemoryLayout<Float>.size * 8,
            bitsPerPixel: MemoryLayout<Float>.size * 8,
            bytesPerRow: Int(self.width) * 4,
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
