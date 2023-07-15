//
//  AverageStackingFilter.swift
//  Astro
//
//  Created by James Wilson on 15/7/2023.
//

import CoreImage

class AverageStackingFilter: CIFilter {
    let kernel: CIColorKernel
    var inputCurrentStack: CIImage?
    var inputNewImage: CIImage?
    var inputStackCount = 1.0

    override init() {
        // 1
        guard let url = Bundle.main.url(forResource: "default",
                                        withExtension: "metallib")
        else {
            fatalError("Check your build settings.")
        }
        do {
            // 2
            let data = try Data(contentsOf: url)
            // 3
            kernel = try CIColorKernel(
                functionName: "avgStacking",
                fromMetalLibraryData: data)
        } catch {
            print(error.localizedDescription)
            fatalError("Make sure the function names match")
        }
        // 4
        super.init()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func outputImage() -> CIImage? {
        guard
            let inputCurrentStack = inputCurrentStack,
            let inputNewImage = inputNewImage
        else {
            return nil
        }
        return kernel.apply(
            extent: inputCurrentStack.extent,
            arguments: [inputCurrentStack, inputNewImage, inputStackCount])
    }
}
