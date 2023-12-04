//
//  FITS.swift
//  Astro
//
//  Created by James Wilson on 5/7/2023.
//

import AppKit
import CryptoKit
import Foundation

enum FITSHeaderKeywordError: Error {
    case recordTooBig
}

class FITSHeaderKeyword: CustomDebugStringConvertible {
    var name: String
    var _value: String?
    var comment: String?

    init(name: String, value: String? = nil, comment: String? = nil) {
        self.name = name
        self._value = value
        self.comment = comment
    }

    var value: String? {
        guard var value = _value else {
            return nil
        }
        if value.hasPrefix("'") { value.removeFirst() }
        if value.hasSuffix("'") { value.removeLast() }
        return value
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
            self._value = String(bytes: valueAndComment[valueStartIndex..<valueEndIndex], encoding: .ascii)!.trimmingCharacters(in: .whitespaces)
            self.comment = String(bytes: valueAndComment[commentStartIndex..<valueAndComment.endIndex], encoding: .ascii)!.trimmingCharacters(in: .whitespaces)
        } else {
            // No value indicator, just parse comment
            self.comment = String(bytes: record[(record.startIndex + 10)...], encoding: .ascii)!.trimmingCharacters(in: .whitespaces)
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
            throw FITSHeaderKeywordError.recordTooBig
        }
        return bytes
    }
}
