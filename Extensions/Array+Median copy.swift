//
//  Array+Median.swift
//  Astro
//
//  Created by James Wilson on 29/7/2023.
//

import Foundation

extension [UInt16] {
    func median() -> Float {
        let sorted = self
        if sorted.count % 2 == 0 {
            return Float(sorted[sorted.count / 2] + sorted[(sorted.count / 2) - 1]) / 2
        } else {
            return Float(sorted[(sorted.count - 1) / 2])
        }
    }

    func max() -> UInt16 {
        return self[0]
    }
}
