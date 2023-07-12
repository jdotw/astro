//
//  Date+SessionTests.swift
//  AstroTests
//
//  Created by James Wilson on 12/7/2023.
//

@testable import Astro
import XCTest

final class Date_SessionTests: XCTestCase {
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testLocalObservationBeforeMidnight() throws {
        let observationDate = Date(fitsDate: "2021-07-11T12:20:00.0")! // 2021-07-11 22:20 GMT+10
        let sessionDateString = observationDate.sessionDateString()
        XCTAssertEqual(sessionDateString, "20210711")
    }
    
    func testLocalObservationAfterMidnight() throws {
        let observationDate = Date(fitsDate: "2021-07-11T17:20:00.0")! // 2021-07-12 03:20 GMT+10
        let sessionDateString = observationDate.sessionDateString()
        XCTAssertEqual(sessionDateString, "20210711")
    }
    
    func testLocalObservationAfterMidnightFirstDayOfMonth() throws {
        let observationDate = Date(fitsDate: "2021-06-30T17:20:00.0")! // 2021-07-01 03:20 GMT+10
        let sessionDateString = observationDate.sessionDateString()
        XCTAssertEqual(sessionDateString, "20210630")
    }
    
    func testLocalObservationAfterMidnightFirstDayOfYear() throws {
        let observationDate = Date(fitsDate: "2021-12-31T17:20:00.0")! // 2022-01-01 03:20 GMT+10
        let sessionDateString = observationDate.sessionDateString()
        XCTAssertEqual(sessionDateString, "20211231")
    }
    
    func testUTCObservationBeforeMidnight() throws {
        let observationDate = Date(fitsDate: "2021-07-11T22:20:00.0")!
        let sessionDateString = observationDate.sessionDateString(in: TimeZone(secondsFromGMT: 0)!)
        XCTAssertEqual(sessionDateString, "20210711")
    }
    
    func testUTCObservationAfterMidnight() throws {
        let observationDate = Date(fitsDate: "2021-07-12T03:20:00.0")!
        let sessionDateString = observationDate.sessionDateString(in: TimeZone(secondsFromGMT: 0)!)
        XCTAssertEqual(sessionDateString, "20210711")
    }
    
    func testUTCObservationAfterMidnightFirstDayOfMonth() throws {
        let observationDate = Date(fitsDate: "2021-07-01T03:20:00.0")!
        let sessionDateString = observationDate.sessionDateString(in: TimeZone(secondsFromGMT: 0)!)
        XCTAssertEqual(sessionDateString, "20210630")
    }
    
    func testUTCObservationAfterMidnightFirstDayOfYear() throws {
        let observationDate = Date(fitsDate: "2022-01-01T03:20:00.0")!
        let sessionDateString = observationDate.sessionDateString(in: TimeZone(secondsFromGMT: 0)!)
        XCTAssertEqual(sessionDateString, "20211231")
    }
}
