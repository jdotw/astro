//
//  File.swift
//  Astro
//
//  Created by James Wilson on 3/9/2023.
//

import Foundation

extension File {
    var pierSide: String? {
        guard let items = metadata?.allObjects as? [FileMetadata] else { return nil }
        guard let pierSide = items.first(where: { item in
            item.key == "PIERSIDE"
        }) else { return nil }
        return pierSide.string
    }

    var pierSideRotationDegrees: CGFloat {
        guard let pierSide else { return 0.0 }
        if pierSide == "WEST" {
            return 180.0
        } else {
            return 0.0
        }
    }
}
