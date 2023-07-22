//
//  URL+Fits.swift
//  Astro
//
//  Created by James Wilson on 9/7/2023.
//

import Foundation

enum FileType {
    case fits
    case unknown
}

extension URL {
    var isFITS: Bool { pathExtension == "fit" || pathExtension == "fits" }
}
