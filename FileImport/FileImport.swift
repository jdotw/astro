//
//  FileImport.swift
//  Astro
//
//  Created by James Wilson on 15/7/2023.
//

import Foundation

class FileImport: ObservableObject {
    class func importer(forURL url: URL) -> FileImport {
        switch url.pathExtension {
        case "fits":
            return FITSFileImport()
        default:
            return FileImport()
        }
    }
}
