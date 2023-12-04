//
//  URL+Hash.swift
//  Astro
//
//  Created by James Wilson on 26/11/2023.
//

import CryptoKit
import Foundation

extension URL {
    var sha512Hash: String? {
        autoreleasepool {
            let file = try! FileHandle(forReadingFrom: self)
            do {
                let digest = try SHA512.hash(data: file.readToEnd()!)
                return digest.map { String(format: "%02x", $0) }.joined()

            } catch {
                return nil
            }
        }
    }
}
