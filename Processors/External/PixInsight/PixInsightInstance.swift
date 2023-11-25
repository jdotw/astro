//
//  PixInsightController.swift
//  Astro
//
//  Created by James Wilson on 25/11/2023.
//

import Foundation

class PixInsightController {
    static let shared = PixInsightController()

    internal var defaultSlotNumber: Int { return 51 }

    func withInstance(_ block: (PixInsightInstance) -> Void) throws {
        let processor = PixInsightInstance()
        block(processor)
    }
}
