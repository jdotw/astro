//
//  FITS.swift
//  Astro
//
//  Created by James Wilson on 5/7/2023.
//

import CryptoKit
import Foundation

enum FITSHeaderError: Error {
    case unterminatedStringLiteral
}

class FITSFile {
    var url: URL

    init(url: URL) {
        self.url = url
    }

    var headers: [String: FITSFileHeaderKeyword] {
        var headers = [String: FITSFileHeaderKeyword]()
        let file = try! FileHandle(forReadingFrom: url)
        do {
            while let block = try file.readBlock() {
                let recordSize = 80
                for i in 0..<36 {
                    let record = block[i*recordSize..<(i + 1)*recordSize]
                    if let keyword = FITSFileHeaderKeyword(record: record) {
                        headers[keyword.name] = keyword
                    }
                }
                if headers["END"] != nil {
                    break
                }
            }
        } catch {
            print("Error reading block: \(error)")
        }
        return headers
    }

    var fileHash: String? {
        let file = try! FileHandle(forReadingFrom: url)
        do {
            let digest = try SHA512.hash(data: file.readToEnd()!)
            return digest.map { String(format: "%02x", $0) }.joined()
        } catch {
            return nil
        }
    }
}

enum FITSFileHeaderKeywordError: Error {
    case recordTooBig
}

class FITSFileHeaderKeyword: CustomDebugStringConvertible {
    var name: String
    var value: String?
    var comment: String?

    init(name: String, value: String? = nil, comment: String? = nil) {
        self.name = name
        self.value = value
        self.comment = comment
    }

    init?(record: Data) {
        // Parse the keyword name
        guard let name = String(bytes: record[record.startIndex..<record.startIndex + 8], encoding: .ascii)?.trimmingCharacters(in: .whitespaces),
              !name.isEmpty
        else {
            return nil
        }
        self.name = name

        // Check for value indicator
        let valueIndicator = String(bytes: record[(record.startIndex + 8)..<(record.startIndex + 10)], encoding: .ascii)!
        if valueIndicator == "= " {
            // Parse value and comment
            let valueAndComment = record[(record.startIndex + 10)...]
            var valueStartIndex = valueAndComment.startIndex
            var valueEndIndex = valueAndComment.endIndex
            var commentStartIndex = valueAndComment.startIndex
            for j in valueAndComment.startIndex..<valueAndComment.endIndex {
                switch valueAndComment[j] {
                case "'".utf8.first!:
                    if commentStartIndex == valueAndComment.startIndex {
                        if valueStartIndex != valueAndComment.startIndex {
                            // Handle end of string literal
                            valueEndIndex = j
                            commentStartIndex = j + 1
                            break
                        } else {
                            // Handle start of string literal
                            valueStartIndex = j + 1
                        }
                    }
                case "/".utf8.first!:
                    if valueStartIndex == valueAndComment.startIndex ||
                        valueEndIndex != valueAndComment.endIndex
                    {
                        commentStartIndex = j + 1
                        if valueEndIndex == valueAndComment.endIndex {
                            valueEndIndex = j
                        }
                    }
                default: break
                }
            }
            value = String(bytes: valueAndComment[valueStartIndex..<valueEndIndex], encoding: .ascii)!.trimmingCharacters(in: .whitespaces)
            comment = String(bytes: valueAndComment[commentStartIndex..<valueAndComment.endIndex], encoding: .ascii)!.trimmingCharacters(in: .whitespaces)
        } else {
            // No value indicator, just parse comment
            comment = String(bytes: record[(record.startIndex + 10)...], encoding: .ascii)!.trimmingCharacters(in: .whitespaces)
        }
    }

    var debugDescription: String {
        var description = "Name: '\(name)'"
        if let value = value {
            description += " Value: '\(value)'"
        }
        if let comment = comment {
            description += " Comment: '\(comment)'"
        }
        description += ""
        return description
    }

    func bytes() throws -> Data {
        var bytes = Data()
        let paddedName = name.padding(toLength: 8, withPad: " ", startingAt: 0)
        bytes.append(Array(paddedName.utf8), count: 8)
        if let value {
            bytes.append(Array("= ".utf8), count: 2)
            let stringLiteral = "'\(value)'"
            bytes.append(Array(stringLiteral.utf8), count: stringLiteral.count)
            if let comment {
                bytes.append(Array(" / ".utf8), count: 3)
                bytes.append(Array(comment.utf8), count: comment.count)
            }
        }
        if bytes.count < 80 {
            let delta = 80 - bytes.count
            bytes.append(Array("".padding(toLength: delta, withPad: " ", startingAt: 0).utf8), count: delta)
        } else if bytes.count > 80 {
            throw FITSFileHeaderKeywordError.recordTooBig
        }
        return bytes
    }
}

enum FITSFileError: Error {
    case blockTooSmall(_: Int)
}

extension FileHandle {
    func readBlock() throws -> Data? {
        let blockSize = 2880
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

extension Date {
    init?(fitsDate: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        guard let date = formatter.date(from: fitsDate) else {
            return nil
        }
        self = date
    }
}
