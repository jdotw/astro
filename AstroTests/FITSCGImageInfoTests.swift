//
//  FITSCGImageInfoTests.swift
//  AstroTests
//
//  Created by James Wilson on 9/7/2023.
//

@testable import Astro
import XCTest

final class FITSCGImageInfoTests: XCTestCase {
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testFITSCGImageInfo() throws {
        var headers: [String: FITSHeaderKeyword] = [:]
        let width = 400
        let height = 300
        let bitsPerPixel = 16
        let bytesPerPixel = bitsPerPixel / 8
        headers["NAXIS1"] = FITSHeaderKeyword(name: "NAXIS1", value: String(width))
        headers["NAXIS2"] = FITSHeaderKeyword(name: "NAXIS2", value: String(height))
        headers["BITPIX"] = FITSHeaderKeyword(name: "BITPIX", value: String(bitsPerPixel))
        guard let info = FITSCGImageInfo(headers: headers) else {
            XCTFail()
            return
        }
        XCTAssertEqual(info.height, height)
        XCTAssertEqual(info.width, width)
        XCTAssertEqual(info.bitsPerPixel, bitsPerPixel)
        XCTAssertEqual(info.bitsPerComponent, bitsPerPixel)
        XCTAssertEqual(info.bytesPerRow, width * bytesPerPixel)
        XCTAssertNotNil(info.colorSpace)
        XCTAssertEqual(info.bitmapInfo, CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder16Big.rawValue))
        XCTAssertNil(info.decode)
        XCTAssertFalse(info.shouldInterpolate)
        XCTAssertEqual(info.intent, CGColorRenderingIntent.defaultIntent)
    }

    func testFITSCGImageInfoHandlesNegativeBitsPerPixel() throws {
        var headers: [String: FITSHeaderKeyword] = [:]
        let bitsPerPixel = -32
        headers["NAXIS1"] = FITSHeaderKeyword(name: "NAXIS1", value: String(100))
        headers["NAXIS2"] = FITSHeaderKeyword(name: "NAXIS2", value: String(100))
        headers["BITPIX"] = FITSHeaderKeyword(name: "BITPIX", value: String(bitsPerPixel))
        guard let info = FITSCGImageInfo(headers: headers) else {
            XCTFail()
            return
        }
        XCTAssertEqual(info.bitsPerPixel, abs(bitsPerPixel))
        XCTAssertEqual(info.bitsPerComponent, abs(bitsPerPixel))
        XCTAssertTrue(info.bytesPerRow > 0)
    }

    func testFITSCGImageInfoHandles16BitIntBITPIX() throws {
        var headers: [String: FITSHeaderKeyword] = [:]
        let bitsPerPixel = 16
        headers["NAXIS1"] = FITSHeaderKeyword(name: "NAXIS1", value: String(100))
        headers["NAXIS2"] = FITSHeaderKeyword(name: "NAXIS2", value: String(100))
        headers["BITPIX"] = FITSHeaderKeyword(name: "BITPIX", value: String(bitsPerPixel))
        guard let info = FITSCGImageInfo(headers: headers) else {
            XCTFail()
            return
        }
        XCTAssertEqual(info.bitsPerPixel, abs(bitsPerPixel))
        XCTAssertEqual(info.bitmapInfo, CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder16Big.rawValue))
    }

    func testFITSCGImageInfoHandles32BitFPBITPIX() throws {
        var headers: [String: FITSHeaderKeyword] = [:]
        let bitsPerPixel = -32
        headers["NAXIS1"] = FITSHeaderKeyword(name: "NAXIS1", value: String(100))
        headers["NAXIS2"] = FITSHeaderKeyword(name: "NAXIS2", value: String(100))
        headers["BITPIX"] = FITSHeaderKeyword(name: "BITPIX", value: String(bitsPerPixel))
        guard let info = FITSCGImageInfo(headers: headers) else {
            XCTFail()
            return
        }
        XCTAssertEqual(info.bitsPerPixel, abs(bitsPerPixel))
        XCTAssertEqual(info.bitmapInfo, CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder32Big.rawValue | CGBitmapInfo.floatComponents.rawValue))
    }

//    func testPerformanceExample() throws {
//        // This is an example of a performance test case.
//        self.measure {
//            // Put the code you want to measure the time of here.
//        }
//    }
}
