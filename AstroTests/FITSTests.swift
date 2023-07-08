//
//  TestFITS.swift
//  AstroTests
//
//  Created by James Wilson on 8/7/2023.
//

@testable import Astro
import XCTest

final class TestFITS: XCTestCase {
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testRecordWithSlashInStringLiteralUsingBytes() throws {
        let record = Data(Array("TELESCOP= 'EQMOD ASCOM HEQ5/6' / Telescope name                                 ".utf8))
        XCTAssertEqual(record.count, 80)
        guard let parsed = FITSFileHeaderKeyword(record: record) else { XCTFail()
            return
        }
        XCTAssertEqual(parsed.name, "TELESCOP")
        XCTAssertEqual(parsed.value!, "EQMOD ASCOM HEQ5/6")
        XCTAssertEqual(parsed.comment!, "Telescope name")
    }

    func testRecordWithSlashInStringLiteral() throws {
        let keyword = FITSFileHeaderKeyword(name: "TELESCOP",
                                            value: "EQMOD ASCOM HEQ5/6",
                                            comment: "Telescope name")
        let record = try keyword.bytes()
        XCTAssertEqual(record.count, 80)
        guard let parsed = FITSFileHeaderKeyword(record: record) else { XCTFail()
            return
        }
        XCTAssertEqual(keyword.name, parsed.name)
        XCTAssertEqual(keyword.value!, parsed.value!)
        XCTAssertEqual(keyword.comment!, parsed.comment!)
    }

    func testRecordWithoutSlashInStringLiteralUsingBytes() throws {
        let record = Data(Array("TELESCOP= 'EQMOD ASCOM HEQ5-6' / Telescope name                                 ".utf8))
        XCTAssertEqual(record.count, 80)
        guard let parsed = FITSFileHeaderKeyword(record: record) else { XCTFail()
            return
        }
        XCTAssertEqual(parsed.name, "TELESCOP")
        XCTAssertEqual(parsed.value!, "EQMOD ASCOM HEQ5-6")
        XCTAssertEqual(parsed.comment!, "Telescope name")
    }

    func testRecordWithoutSlashInStringLiteral() throws {
        let keyword = FITSFileHeaderKeyword(name: "TELESCOP",
                                            value: "EQMOD ASCOM MOUNT",
                                            comment: "Telescope name")
        let record = try keyword.bytes()
        XCTAssertEqual(record.count, 80)
        guard let parsed = FITSFileHeaderKeyword(record: record) else { XCTFail()
            return
        }
        XCTAssertEqual(keyword.name, parsed.name)
        XCTAssertEqual(keyword.value!, parsed.value!)
        XCTAssertEqual(keyword.comment!, parsed.comment!)
    }

    func testRecordWithSingleQuoteInComment() throws {
        // The ' in the comment should not be treated as
        // a string liter
        let record = Data(Array("SUN_ALT =       69.75344848633 / altitude of the sun above Earth's limb (deg)   ".utf8))
        XCTAssertEqual(record.count, 80)
        guard let parsed = FITSFileHeaderKeyword(record: record) else { XCTFail()
            return
        }
        XCTAssertEqual(parsed.name, "SUN_ALT")
        XCTAssertEqual(parsed.value!, "69.75344848633")
        XCTAssertEqual(parsed.comment!, "altitude of the sun above Earth's limb (deg)")
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
}
