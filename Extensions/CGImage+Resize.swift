//
//  CGImage+Resize.swift
//  Astro
//
//  Created by James Wilson on 18/7/2023.
//

import CoreGraphics
import Foundation

extension CGImage {
    func resize(to size: CGSize) -> CGImage? {
        let context = CGContext(data: nil,
                                width: Int(size.width),
                                height: Int(size.height),
                                bitsPerComponent: self.bitsPerComponent,
                                bytesPerRow: 0,
                                space: self.colorSpace ?? CGColorSpace(name: CGColorSpace.sRGB)!,
                                bitmapInfo: self.bitmapInfo.rawValue)
        context?.interpolationQuality = .high
        context?.draw(self, in: CGRect(origin: .zero, size: size))
        return context?.makeImage()
    }
}
