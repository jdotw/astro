//
//  XISFFile.swift
//  Astro
//
//  Created by James Wilson on 26/11/2023.
//

import Foundation

class XISFFile: NSObject {
    let url: URL
    
    var images: [XISFImage] = []

    init(url: URL) {
        self.url = url
    }

    var headerData: Data? {
        guard let file = try? FileHandle(forReadingFrom: url)
        else {
            return nil
        }

        var headerLength: UInt32!
        do {
            try file.seek(toOffset: 8) // Start of header length
            let headerLengthData = file.readData(ofLength: 4)
            headerLength = headerLengthData.withUnsafeBytes {
                UInt32(littleEndian: $0.load(as: UInt32.self))
            }
            print("HEADER LENGTH: ", headerLength!)
        } catch {
            print("Failed to read header length: ", error)
            return nil
        }

        do {
            try file.seek(toOffset: 16) // Start of header data
            let headerData = file.readData(ofLength: Int(headerLength))
            return headerData
        } catch {
            print("Failed to read header data: ", error)
            return nil
        }
    }

    func parseHeaders() -> [String: String]? {
        guard let headerData = headerData else { return nil }
        let xml = XMLParser(data: headerData)
        let parserDelegate = XISFFileXMLParserDelegate(url: url)
        xml.delegate = parserDelegate
        xml.parse()
        images = parserDelegate.images
        return [:]
    }
}

class XISFFileXMLParserDelegate: NSObject, XMLParserDelegate {
    let url: URL
    var images: [XISFImage] = []
    
    private var currentImage: XISFImage?
    
    init(url: URL) {
        self.url = url
    }

    func parserDidStartDocument(_ parser: XMLParser) {
        print("didStartDocument")
    }
    
    func parserDidEndDocument(_ parser: XMLParser) {
        print("didEndDocument")
    }
    
//    optional func parser(_ parser: XMLParser, foundNotationDeclarationWithName name: String, publicID: String?, systemID: String?)
    
//    optional func parser(_ parser: XMLParser, foundUnparsedEntityDeclarationWithName name: String, publicID: String?, systemID: String?, notationName: String?)
    
//    optional func parser(_ parser: XMLParser, foundAttributeDeclarationWithName attributeName: String, forElement elementName: String, type: String?, defaultValue: String?)
    
//    optional func parser(_ parser: XMLParser, foundElementDeclarationWithName elementName: String, model: String)
    
//    optional func parser(_ parser: XMLParser, foundInternalEntityDeclarationWithName name: String, value: String?)
    
//    optional func parser(_ parser: XMLParser, foundExternalEntityDeclarationWithName name: String, publicID: String?, systemID: String?)
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        print("didStartElement name=\(elementName) attributes=\(attributeDict)")
        
        switch elementName {
        case "Image":
            let image = XISFImage(url: url, xmlAttributes: attributeDict)
            images.append(image)
            currentImage = image
        default:
            if let currentImage {
                currentImage.parser(parser, didStartElement: elementName, namespaceURI: namespaceURI, qualifiedName: qName, attributes: attributeDict)
            } else {
                print("Ignoring element: ", elementName)
            }
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        print("didEndElement name=\(elementName)")
        switch elementName {
        case "Image":
            currentImage = nil
        default:
            if let currentImage {
                currentImage.parser(parser, didEndElement: elementName, namespaceURI: namespaceURI, qualifiedName: qName)
            }
        }
    }
    
//    optional func parser(_ parser: XMLParser, didStartMappingPrefix prefix: String, toURI namespaceURI: String)
    
//    optional func parser(_ parser: XMLParser, didEndMappingPrefix prefix: String)
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        print("foundCharacters: \(string)")
    }
    
//    optional func parser(_ parser: XMLParser, foundIgnorableWhitespace whitespaceString: String)
    
//    optional func parser(_ parser: XMLParser, foundProcessingInstructionWithTarget target: String, data: String?)
    
//    optional func parser(_ parser: XMLParser, foundComment comment: String)
    
//    optional func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data)
    
//    optional func parser(_ parser: XMLParser, resolveExternalEntityName name: String, systemID: String?) -> Data?
    
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        print("PARSER ERROR: ", parseError)
    }
    
    func parser(_ parser: XMLParser, validationErrorOccurred validationError: Error) {
        print("VALIDATION ERROR: ", validationError)
    }
}

class XISFImage: NSObject {
    let url: URL
    let colorSpace: String?
    let sampleFormat: String?
    let bounds: String?
    let location: String?
    let geometry: String?
    
    var fitsKeywords: [String: FITSHeaderKeyword] = [:]
    
    init(url: URL, xmlAttributes: [String: String]) {
        self.url = url
        self.colorSpace = xmlAttributes["colorSpace"]
        self.sampleFormat = xmlAttributes["sampleFormat"]
        self.bounds = xmlAttributes["bounds"]
        self.location = xmlAttributes["location"]
        self.geometry = xmlAttributes["geometry"]
        super.init()
    }
    
    private var locationComponents: [String] {
        return location?.components(separatedBy: ":") ?? []
    }
    
    private var offset: Int? {
        return Int(locationComponents[1])
    }
    
    private var length: Int? {
        return Int(locationComponents[2])
    }
    
    private var geometryComponents: [String] {
        return geometry?.components(separatedBy: ":") ?? []
    }

    var width: Int? {
        return Int(geometryComponents[0])
    }

    var height: Int? {
        return Int(geometryComponents[1])
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        print("IMAGE HANDLING \(elementName): \(attributeDict)")
        switch elementName {
        case "FITSKeyword":
            if let kw = FITSHeaderKeyword(xmlAttributes: attributeDict) {
                fitsKeywords[kw.name] = kw
            }
        default:
            break
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        print("IMAGE didEndElement name=\(elementName)")
    }
    
    func getImageData() throws -> Data {
        guard let location = location else {
            throw XISFImageError.missingLocation
        }
        let fileReader = try FileHandle(forReadingFrom: url)
        let locationParts = location.components(separatedBy: ":")
        guard let offset = UInt64(locationParts[1]) else {
            throw XISFImageError.missingLocationOffset
        }
        try fileReader.seek(toOffset: offset)
        guard let length = UInt64(locationParts[2]) else {
            throw XISFImageError.missingLocationLength
        }
        do {
            guard let data = try fileReader.read(upToCount: Int(length)) else {
                throw XISFImageError.dataReadError(nil)
            }
            return data
        } catch {
            throw XISFImageError.dataReadError(error)
        }
    }
}

enum XISFImageError: Error {
    case missingLocation
    case missingLocationOffset
    case missingLocationLength
    case dataReadError(Error?)
}

extension FITSHeaderKeyword {
    convenience init?(xmlAttributes: [String: String]) {
        guard let name = xmlAttributes["name"] else { return nil }
        self.init(name: name, value: xmlAttributes["value"], comment: xmlAttributes["comment"])
    }
}
