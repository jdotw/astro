//
//  CGImage+Filter.swift
//  Astro
//
//  Created by James Wilson on 18/7/2023.
//

import CoreGraphics
import CoreImage
import Foundation

extension CGImage {
    func adjustBrightnessAndContrast(brightness: Float, contrast: Float) -> CGImage? {
        let ciContext = CIContext(options: nil)
        
        // Change the CGImage into a CIImage
        let ciImage = CIImage(cgImage: self)
        
        // Set up a filter to adjust brightness and contrast
        guard let filter = CIFilter(name: "CIColorControls") else {
            return nil
        }
        
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(brightness, forKey: kCIInputBrightnessKey)
        filter.setValue(contrast, forKey: kCIInputContrastKey)
        
        // Get the image from the filter
        guard let outputCIImage = filter.outputImage else {
            return nil
        }
        
        // Change the output CIImage back to a CGImage
        let outputCGImage = ciContext.createCGImage(outputCIImage, from: outputCIImage.extent)
        return outputCGImage
    }
    
    func adjustExposure(inputImage: CGImage, ev: Float = 1.0) -> CGImage? {
        let ciContext = CIContext()
        
        // Convert the CGImage to a CIImage
        let ciImage = CIImage(cgImage: inputImage)
        
        // Create a filter to adjust exposure
        guard let filter = CIFilter(name: "CIExposureAdjust") else {
            return nil
        }
        
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(ev, forKey: kCIInputEVKey) // Increase exposure
        
        // Get the output image from the filter
        guard let outputCIImage = filter.outputImage else {
            return nil
        }
        
        // Convert the output CIImage to a CGImage
        let outputCGImage = ciContext.createCGImage(outputCIImage, from: outputCIImage.extent)
        return outputCGImage
    }
    
    func createHistogram(inputImage: CGImage) -> CGImage? {
        let ciContext = CIContext()
        
        // Convert the CGImage to a CIImage
        let ciImage = CIImage(cgImage: inputImage)
        
        // Create an area histogram filter
        guard let areaHistogramFilter = CIFilter(name: "CIAreaHistogram") else {
            return nil
        }
        
        areaHistogramFilter.setValue(ciImage, forKey: kCIInputImageKey)
        areaHistogramFilter.setValue(CIVector(cgRect: ciImage.extent), forKey: kCIInputExtentKey)
        areaHistogramFilter.setValue(256, forKey: "inputCount") // Number of bins
        areaHistogramFilter.setValue(1.0, forKey: "inputScale") // Scaling factor
        
        // Get the histogram data from the filter
        guard let histogramData = areaHistogramFilter.outputImage else {
            return nil
        }
        
        // Create a histogram display filter
        guard let histogramDisplayFilter = CIFilter(name: "CIHistogramDisplayFilter") else {
            return nil
        }
        
        histogramDisplayFilter.setValue(histogramData, forKey: kCIInputImageKey)
        histogramDisplayFilter.setValue(300, forKey: "inputHeight") // Height of the histogram
        histogramDisplayFilter.setValue(1.0, forKey: "inputHighLimit") // Maximum intensity
        histogramDisplayFilter.setValue(0.0, forKey: "inputLowLimit") // Minimum intensity
        
        // Get the output image from the filter
        guard let outputCIImage = histogramDisplayFilter.outputImage else {
            return nil
        }
        
        // Convert the output CIImage to a CGImage
        let outputCGImage = ciContext.createCGImage(outputCIImage, from: outputCIImage.extent)
        return outputCGImage
    }
}
