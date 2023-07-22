//
//  URL+FileTypeTests.swift
//  AstroTests
//
//  Created by James Wilson on 21/7/2023.
//

import XCTest

@testable import Astro

final class URL_FileTypeTests: XCTestCase {
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExtensionFITIsFIT() throws {
        let url = URL(fileURLWithPath: "/Users/test/Downloads/NGC253.fit")
        XCTAssertTrue(url.isFITS)
    }

    func testExtensionFITIsFITS() throws {
        let url = URL(fileURLWithPath: "/Users/test/Downloads/NGC253.fits")
        XCTAssertTrue(url.isFITS)
    }
}
