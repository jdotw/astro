//
//  FileHandle+HITS.swift
//  Astro
//
//  Created by James Wilson on 9/7/2023.
//

import Foundation

extension FileHandle {
    func readBlock(size blockSize: Int = 2880) throws -> Data? {
        if let block = try read(upToCount: blockSize) {
            if block.count < blockSize {
                throw FITSFileError.blockTooSmall(block.count)
            }
            return block
        } else {
            return nil
        }
    }
}
