//
//  URL+FITSTests.swift
//  AstroTests
//
//  Created by James Wilson on 9/7/2023.
//

@testable import Astro
import XCTest

final class URL_FITSTests: XCTestCase {
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testURLHasFITSExtension() throws {
        let url = URL(fileURLWithPath: "/2023-07-07T13:05:23.204_0001.fits")
        XCTAssertTrue(url.isFITS)
    }

    func testURLHasFITExtension() throws {
        let url = URL(fileURLWithPath: "/2023-07-07T13:05:23.204_0001.fit")
        XCTAssertTrue(url.isFITS)
    }

    func testURLHasXSIFExtension() throws {
        let url = URL(fileURLWithPath: "/2023-07-07T13:05:23.204_0001.xsif")
        XCTAssertFalse(url.isFITS)
    }
}
