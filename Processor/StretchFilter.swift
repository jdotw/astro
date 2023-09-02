//
//  AverageStackingFilter.swift
//  Astro
//
//  Created by James Wilson on 15/7/2023.
//

import CoreImage

class StretchFilter: CIFilter {
    let kernel: CIColorKernel
    var inputImage: CIImage
    var statistics: FileStatistics

    init(inputImage: CIImage, statistics: FileStatistics) {
        guard let url = Bundle.main.url(forResource: "default",
                                        withExtension: "metallib")
        else {
            fatalError("Check your build settings.")
        }
        do {
            let data = try Data(contentsOf: url)
            self.kernel = try CIColorKernel(
                functionName: "stretch",
                fromMetalLibraryData: data)
        } catch {
            print(error.localizedDescription)
            fatalError("Make sure the function names match")
        }
        self.inputImage = inputImage
        self.statistics = statistics
        super.init()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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

    override var outputImage: CIImage? {
        // NOTE: We found out the hard way that when the
        // pixel data is sent to the metal shader, it undergoes
        // a conversion from srgb to linear which means in
        // the shader itself we have to undo this and switch
        // back to srgb to ensure these shadowClip and midtone
        // values are relevant to the pixel data in the shader
        let shadowClipConst = Float(-1.25)
        let shadowClip = statistics.median + (shadowClipConst * statistics.avgMedianDeviation)
        let targetBG = Float(0.25)
        let midtone = mtf(midtone: targetBG, x: statistics.median - shadowClip)
        let image = kernel.apply(
            extent: inputImage.extent,
            arguments: [inputImage, midtone, shadowClip])
        return image
    }
}
