//
//  FileImportURL.swift
//  Astro
//
//  Created by James Wilson on 21/7/2023.
//

import Foundation

enum ImportFileListError: Error {
    case failedToReadURLInfo(URL)
    case failedToStartSecurityScopedAccess(URL)
}

struct ImportFileList {
    var baseURL: URL
    var files: [URL]

    init(at baseURL: URL) throws {
        self.baseURL = baseURL
        self.files = try ImportFileList.buildFileList(at: baseURL)
    }

    static func buildFileList(at baseURL: URL) throws -> [URL] {
        guard let resourceValues = try? baseURL.resourceValues(forKeys: Set<URLResourceKey>([.isDirectoryKey])),
              let isDirectory = resourceValues.isDirectory
        else {
            throw ImportFileListError.failedToReadURLInfo(baseURL)
        }
        var files = [URL]()
        if isDirectory {
            let enumerator = FileManager.default.enumerator(at: baseURL, includingPropertiesForKeys: nil)
            while let childURL = enumerator?.nextObject() as? URL {
                files.append(childURL)
            }
        } else {
            files.append(baseURL)
        }
        return files
    }
}
