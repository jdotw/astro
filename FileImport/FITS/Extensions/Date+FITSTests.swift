//
//  Date+FITSTests.swift
//  AstroTests
//
//  Created by James Wilson on 9/7/2023.
//

@testable import Astro
import XCTest

final class Date_FITSTests: XCTestCase {
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testCanParseISODateFormat() throws {
        guard let date = Date(fitsDate: "2023-07-09T16:12:34.567890") else {
            XCTFail()
            return
        }
        let components = Calendar.current.dateComponents(in: TimeZone(secondsFromGMT: 0)!, from: date)
        XCTAssertEqual(components.year, 2023)
        XCTAssertEqual(components.month, 7)
        XCTAssertEqual(components.day, 9)
        XCTAssertEqual(components.hour, 16)
        XCTAssertEqual(components.minute, 12)
        XCTAssertEqual(components.second, 34)
    }

    func testCanParseISODateFormatWithoutSubSeconds() throws {
        guard let date = Date(fitsDate: "2018-09-02T01:33:54") else {
            XCTFail()
            return
        }
        let components = Calendar.current.dateComponents(in: TimeZone(secondsFromGMT: 0)!, from: date)
        XCTAssertEqual(components.year, 2018)
        XCTAssertEqual(components.month, 9)
        XCTAssertEqual(components.day, 2)
        XCTAssertEqual(components.hour, 1)
        XCTAssertEqual(components.minute, 33)
        XCTAssertEqual(components.second, 54)
    }

    
    func testCanParseShortDateFormatWithSingleDigitDay() throws {
        guard let date = Date(fitsDate: "2/07/96") else {
            XCTFail()
            return
        }
        let components = Calendar.current.dateComponents(in: TimeZone(secondsFromGMT: 0)!, from: date)
        XCTAssertEqual(components.year, 1996)
        XCTAssertEqual(components.month, 7)
        XCTAssertEqual(components.day, 2)
        XCTAssertEqual(components.hour, 0)
        XCTAssertEqual(components.minute, 0)
        XCTAssertEqual(components.second, 0)
    }
    
    func testCanParseShortDateFormatWithDoubleDigitDay() throws {
        guard let date = Date(fitsDate: "21/07/96") else {
            XCTFail()
            return
        }
        let components = Calendar.current.dateComponents(in: TimeZone(secondsFromGMT: 0)!, from: date)
        XCTAssertEqual(components.year, 1996)
        XCTAssertEqual(components.month, 7)
        XCTAssertEqual(components.day, 21)
        XCTAssertEqual(components.hour, 0)
        XCTAssertEqual(components.minute, 0)
        XCTAssertEqual(components.second, 0)
    }
    
    func testCanParseShortDateFormatWithSingleDigitMonth() throws {
        guard let date = Date(fitsDate: "21/7/96") else {
            XCTFail()
            return
        }
        let components = Calendar.current.dateComponents(in: TimeZone(secondsFromGMT: 0)!, from: date)
        XCTAssertEqual(components.year, 1996)
        XCTAssertEqual(components.month, 7)
        XCTAssertEqual(components.day, 21)
        XCTAssertEqual(components.hour, 0)
        XCTAssertEqual(components.minute, 0)
        XCTAssertEqual(components.second, 0)
    }
}
