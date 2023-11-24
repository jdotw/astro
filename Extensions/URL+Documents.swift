//
//  URL+Documents.swift
//  Astro
//
//  Created by James Wilson on 25/11/2023.
//

import Foundation

extension URL {
    static var documentsDirectory: URL? {
        guard let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        return docsURL.appending(path: "Astro")
    }
}
