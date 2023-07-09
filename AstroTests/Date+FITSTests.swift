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
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
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
