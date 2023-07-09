//
//  TestFITS.swift
//  AstroTests
//
//  Created by James Wilson on 8/7/2023.
//

@testable import Astro
import XCTest

final class FileHandle_FITSTests: XCTestCase {
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testTimestampWithDecimalAndNoTimeZone() throws {
        let value = "2023-07-07T13:05:23.204"
        let date = Date(fitsDate: value)
        XCTAssertNotNil(date)
        let components = Calendar.current.dateComponents(in: TimeZone(secondsFromGMT: 0)!, from: date!)
        XCTAssertEqual(components.year, 2023)
        XCTAssertEqual(components.month, 7)
        XCTAssertEqual(components.day, 7)
        XCTAssertEqual(components.hour, 13)
        XCTAssertEqual(components.minute, 5)
        XCTAssertEqual(components.second, 23)
        XCTAssertEqual(Double(components.nanosecond!), 204000000.0, accuracy: 10.0)
    }

    func testTypeWithoutFRAMEHeader() throws {
        let headers: [String: FITSHeaderKeyword] = [:]
        let file = FITSFile(headers: headers)
        XCTAssertEqual(file.type, "light")
    }

    func testTypeWithFRAMEHeader() throws {
        let headers: [String: FITSHeaderKeyword] = ["FRAME": FITSHeaderKeyword(name: "FRAME", value: "Dark", comment: "")]
        let file = FITSFile(headers: headers)
        XCTAssertEqual(file.type, "dark")
    }
}
