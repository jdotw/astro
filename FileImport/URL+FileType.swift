//
//  URL+Fits.swift
//  Astro
//
//  Created by James Wilson on 9/7/2023.
//

import Foundation

extension URL {
    var isFITS: Bool { pathExtension == "fit" || pathExtension == "fits" }
}
