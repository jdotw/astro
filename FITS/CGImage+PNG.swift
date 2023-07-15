//
//  CGImage+PNG.swift
//  Astro
//
//  Created by James Wilson on 14/7/2023.
//

import CoreGraphics
import CoreImage
import Foundation
import ImageIO
import UniformTypeIdentifiers

public extension CGImage {
    func pngData() -> Data? {
        let cfdata: CFMutableData = CFDataCreateMutable(nil, 0)
        if let destination = CGImageDestinationCreateWithData(cfdata, UTType.png.identifier as CFString, 1, nil) {
            CGImageDestinationAddImage(destination, self, nil)
            if CGImageDestinationFinalize(destination) {
                return cfdata as Data
            }
        }

        return nil
    }
}
