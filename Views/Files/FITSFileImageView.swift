//
//  FITSFileImageView.swift
//  Astro
//
//  Created by James Wilson on 14/7/2023.
//

import SwiftUI

struct FITSFileImageView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @ObservedObject var fits: FITSFile
    var exposure: Double = 1.0

    var exposedImage: CGImage? {
        guard let image = fits.cgImage
        else {
            return nil
        }
        return fits.adjustExposure(inputImage: image, ev: Float(exposure))
    }

    var nsImage: NSImage {
        guard let exposedImage = exposedImage else {
            return NSImage(size: NSSize(width: 10.0, height: 10.0))
        }
        return NSImage(cgImage: exposedImage, size: NSSize.zero)
    }

    var histogramImage: NSImage {
        guard let exposedImage = exposedImage,
              let histogram = fits.createHistogram(inputImage: exposedImage)
        else {
            return NSImage(size: NSSize(width: 10.0, height: 10.0))
        }
        return NSImage(cgImage: histogram, size: NSSize.zero)
    }

    var body: some View {
        VStack {
            if let _ = fits.cgImage {
                VStack {
                    Image(nsImage: self.nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                    Image(nsImage: self.histogramImage)
                        .aspectRatio(contentMode: .fit)
                }
            } else {
                Text("Loading...")
            }
        }
    }
}
