//
//  File+RegionTests.swift
//  AstroTests
//
//  Created by James Wilson on 24/8/2023.
//

@testable import Astro
import XCTest

final class File_RegionTests: XCTestCase {
    override func setUpWithError() throws {}

    override func tearDownWithError() throws {}

    let n = UInt8(UINT8_MAX)
    let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)

    func file(size: CGSize) -> File {
        let file = File(context: context)
        file.width = Int32(size.width)
        file.height = Int32(size.height)
        return file
    }

    func image(fromPixels pixels: [UInt8], width: Int, height: Int) -> CGImage? {
        let data = pixels.withUnsafeBytes { Data($0) }
        let dataProvider = CGDataProvider(data: data as CFData)
        return CGImage(width: width,
                       height: height,
                       bitsPerComponent: 8,
                       bitsPerPixel: 8,
                       bytesPerRow: width,
                       space: CGColorSpaceCreateDeviceGray(),
                       bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
                       provider: dataProvider!,
                       decode: nil,
                       shouldInterpolate: false,
                       intent: .defaultIntent)
    }

    func testSingleRect() throws {
        var pixels: [UInt8] = [0, 0, n, 0, 0, 0,
                               0, n, n, 0, 0, 0,
                               0, n, n, n, n, 0,
                               0, 0, n, 0, 0, 0]
        let file = file(size: CGSize(width: 6, height: 4))
        let regions = file.detectRegions(inPixels: &pixels, minimumSize: CGSize(width: 2.0, height: 2.0))
        XCTAssertEqual(regions.count, 1)
        guard let region = regions.first else {
            return XCTFail()
        }
        XCTAssertEqual(region.x, 1)
        XCTAssertEqual(region.y, 0)
        XCTAssertEqual(region.width, 4)
        XCTAssertEqual(region.height, 4)
    }

    func testTwoRects() throws {
        var pixels: [UInt8] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, 0, n, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, n, n, n, 0, 0, 0, 0, 0, 0, 0,
                               0, n, n, n, n, n, 0, 0, 0, 0, 0, 0,
                               0, 0, n, n, n, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, 0, n, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, 0, 0, 0, n, n, 0, 0, 0, 0, 0,
                               0, 0, 0, n, n, n, n, 0, 0, 0, 0, 0,
                               0, 0, 0, 0, n, n, n, 0, 0, n, n, 0,
                               0, 0, 0, 0, 0, n, 0, 0, 0, n, n, 0,
                               0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        let file = file(size: CGSize(width: 12, height: 12))
        let regions = file.detectRegions(inPixels: &pixels, minimumSize: CGSize(width: 3.0, height: 3.0))
        XCTAssertEqual(regions.count, 2)
        guard let first = regions.first else {
            return XCTFail()
        }
        XCTAssertEqual(first.x, 1)
        XCTAssertEqual(first.y, 1)
        XCTAssertEqual(first.width, 5)
        XCTAssertEqual(first.height, 5)
        let second = regions[1]
        XCTAssertEqual(second.x, 3)
        XCTAssertEqual(second.y, 6)
        XCTAssertEqual(second.width, 4)
        XCTAssertEqual(second.height, 4)
    }

    func testTooSmallRects() throws {
        var pixels: [UInt8] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, 0, n, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, n, n, n, 0, 0, 0, 0, n, 0, 0, 0,
                               0, 0, 0, 0, 0, 0, 0, 0, 0, n, n, 0,
                               0, 0, 0, 0, n, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, 0, 0, 0, 0, n, 0, 0, 0, 0, 0,
                               0, 0, 0, 0, 0, 0, n, 0, 0, 0, 0, 0,
                               0, 0, 0, 0, 0, n, n, 0, 0, n, 0, 0,
                               0, 0, 0, 0, 0, 0, 0, 0, 0, n, n, 0,
                               0, 0, 0, n, 0, 0, 0, 0, 0, n, n, 0,
                               0, 0, n, n, n, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        let file = file(size: CGSize(width: 12, height: 12))
        let regions = file.detectRegions(inPixels: &pixels, minimumSize: CGSize(width: 4.0, height: 4.0))
        XCTAssertEqual(regions.count, 0)
    }

    func testTooSmallRectByWidth() throws {
        var pixels: [UInt8] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, 0, n, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, n, n, n, 0, 0, 0, 0, n, 0, 0, 0,
                               0, 0, 0, 0, 0, 0, 0, 0, 0, n, n, 0,
                               0, 0, 0, 0, n, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, 0, 0, 0, 0, n, 0, 0, 0, 0, 0,
                               0, 0, 0, 0, 0, 0, n, 0, 0, 0, 0, 0,
                               0, 0, 0, 0, 0, n, n, 0, 0, n, 0, 0,
                               0, 0, 0, 0, 0, 0, 0, 0, 0, n, n, 0,
                               0, 0, 0, n, 0, 0, 0, 0, 0, n, n, 0,
                               0, 0, n, n, n, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        let file = file(size: CGSize(width: 12, height: 12))
        let regions = file.detectRegions(inPixels: &pixels, minimumSize: CGSize(width: 4.0, height: 2.0))
        XCTAssertEqual(regions.count, 0)
    }

    func testTooSmallRectByHeight() throws {
        var pixels: [UInt8] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, 0, n, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, n, n, n, 0, 0, 0, 0, n, 0, 0, 0,
                               0, 0, 0, 0, 0, 0, 0, 0, 0, n, n, 0,
                               0, 0, 0, 0, n, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, 0, 0, 0, 0, n, 0, 0, 0, 0, 0,
                               0, 0, 0, 0, 0, 0, n, 0, 0, 0, 0, 0,
                               0, 0, 0, 0, 0, n, n, 0, 0, n, 0, 0,
                               0, 0, 0, 0, 0, 0, 0, 0, 0, n, n, 0,
                               0, 0, 0, n, 0, 0, 0, 0, 0, n, n, 0,
                               0, 0, n, n, n, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        let file = file(size: CGSize(width: 12, height: 12))
        let regions = file.detectRegions(inPixels: &pixels, minimumSize: CGSize(width: 2.0, height: 4.0))
        XCTAssertEqual(regions.count, 0)
    }

    func testDiagonalBottomLeftRect() throws {
        var pixels: [UInt8] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, n, n, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, n, n, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, n, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        let file = file(size: CGSize(width: 12, height: 12))
        let regions = file.detectRegions(inPixels: &pixels, minimumSize: CGSize(width: 2.0, height: 2.0))
        XCTAssertEqual(regions.count, 1)
        guard let first = regions.first else {
            return XCTFail()
        }
        XCTAssertEqual(first.x, 1)
        XCTAssertEqual(first.y, 3)
        XCTAssertEqual(first.width, 3)
        XCTAssertEqual(first.height, 3)
    }

    func testDiagonalTopLeftRect() throws {
        var pixels: [UInt8] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, n, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, n, n, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, n, n, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        let file = file(size: CGSize(width: 12, height: 12))
        let regions = file.detectRegions(inPixels: &pixels, minimumSize: CGSize(width: 2.0, height: 2.0))
        XCTAssertEqual(regions.count, 1)
        guard let first = regions.first else {
            return XCTFail()
        }
        XCTAssertEqual(first.x, 1)
        XCTAssertEqual(first.y, 2)
        XCTAssertEqual(first.width, 3)
        XCTAssertEqual(first.height, 3)
    }

    func testDiagonalTopRightRect() throws {
        var pixels: [UInt8] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, 0, 0, n, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, n, n, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, n, n, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        let file = file(size: CGSize(width: 12, height: 12))
        let regions = file.detectRegions(inPixels: &pixels, minimumSize: CGSize(width: 2.0, height: 2.0))
        XCTAssertEqual(regions.count, 1)
        guard let first = regions.first else {
            return XCTFail()
        }
        XCTAssertEqual(first.x, 2)
        XCTAssertEqual(first.y, 2)
        XCTAssertEqual(first.width, 3)
        XCTAssertEqual(first.height, 3)
    }

    func testDiagonalBottomRightRect() throws {
        var pixels: [UInt8] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, n, n, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, n, n, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, 0, 0, n, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        let file = file(size: CGSize(width: 12, height: 12))
        let regions = file.detectRegions(inPixels: &pixels, minimumSize: CGSize(width: 2.0, height: 2.0))
        XCTAssertEqual(regions.count, 1)
        guard let first = regions.first else {
            return XCTFail()
        }
        XCTAssertEqual(first.x, 2)
        XCTAssertEqual(first.y, 3)
        XCTAssertEqual(first.width, 3)
        XCTAssertEqual(first.height, 3)
    }

    func testDiagonalLeftRect() throws {
        var pixels: [UInt8] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, n, n, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, n, 0, n, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, n, n, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        let file = file(size: CGSize(width: 12, height: 12))
        let regions = file.detectRegions(inPixels: &pixels, minimumSize: CGSize(width: 2.0, height: 2.0))
        XCTAssertEqual(regions.count, 1)
        guard let first = regions.first else {
            return XCTFail()
        }
        XCTAssertEqual(first.x, 1)
        XCTAssertEqual(first.y, 3)
        XCTAssertEqual(first.width, 3)
        XCTAssertEqual(first.height, 3)
    }

    func testDiagonalBottomRect() throws {
        var pixels: [UInt8] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, n, n, n, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, n, 0, n, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, 0, n, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        let file = file(size: CGSize(width: 12, height: 12))
        let regions = file.detectRegions(inPixels: &pixels, minimumSize: CGSize(width: 2.0, height: 2.0))
        XCTAssertEqual(regions.count, 1)
        guard let first = regions.first else {
            return XCTFail()
        }
        XCTAssertEqual(first.x, 2)
        XCTAssertEqual(first.y, 3)
        XCTAssertEqual(first.width, 3)
        XCTAssertEqual(first.height, 3)
    }

    func testDiagonalRightRect() throws {
        var pixels: [UInt8] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, n, n, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, n, 0, n, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, n, n, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        let file = file(size: CGSize(width: 12, height: 12))
        let regions = file.detectRegions(inPixels: &pixels, minimumSize: CGSize(width: 2.0, height: 2.0))
        XCTAssertEqual(regions.count, 1)
        guard let first = regions.first else {
            return XCTFail()
        }
        XCTAssertEqual(first.x, 2)
        XCTAssertEqual(first.y, 3)
        XCTAssertEqual(first.width, 3)
        XCTAssertEqual(first.height, 3)
    }

    func testDetectedPixelsErased() throws {
        var pixels: [UInt8] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, 0, n, 0, 0, 0, 0, n, 0, 0, 0,
                               0, 0, n, n, n, 0, 0, 0, 0, n, 0, 0,
                               0, n, n, n, n, n, 0, 0, 0, 0, 0, 0,
                               0, 0, n, n, n, 0, 0, 0, 0, 0, 0, n,
                               0, 0, 0, n, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, 0, 0, 0, n, n, 0, 0, 0, 0, 0,
                               0, 0, 0, n, n, n, n, 0, 0, 0, 0, 0,
                               0, 0, 0, 0, n, n, n, 0, 0, n, n, 0,
                               0, 0, 0, 0, 0, n, 0, 0, 0, n, n, 0,
                               0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, 0, 0, 0, 0, n, 0, 0, 0, 0, 0]
        let file = file(size: CGSize(width: 12, height: 12))
        let regions = file.detectRegions(inPixels: &pixels, minimumSize: CGSize(width: 3.0, height: 3.0))
        XCTAssertGreaterThan(regions.count, 0)
        for pixel in pixels {
            XCTAssertNotEqual(pixel, n)
        }
    }

    func testDiagonalTrailingTopRightRect() throws {
        var pixels: [UInt8] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, 0, 0, n, 0, 0, 0, 0, 0, 0, 0,
                               0, n, 0, n, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, n, n, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, n, n, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                               0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        let file = file(size: CGSize(width: 12, height: 12))
        let regions = file.detectRegions(inPixels: &pixels, minimumSize: CGSize(width: 2.0, height: 2.0))
        XCTAssertEqual(regions.count, 1)
        guard let first = regions.first else {
            return XCTFail()
        }
        XCTAssertEqual(first.x, 1)
        XCTAssertEqual(first.y, 1)
        XCTAssertEqual(first.width, 4)
        XCTAssertEqual(first.height, 4)
    }
}
