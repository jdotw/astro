//
//  TransientWindowEnum.swift
//  Astro
//
//  Created by James Wilson on 27/12/2023.
//

import Foundation

enum TransientWindowType: Identifiable, Codable {
    var id: Self { self }
    case targetExportRequestList
}
