//
//  Region+Tests.swift
//  AstroTests
//
//  Created by James Wilson on 30/8/2023.
//

@testable import Astro
import XCTest

final class Region_Tests: XCTestCase {
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testRegionInit() throws {
        let rect = CGRect(x: 1.0, y: 2.0, width: 3.0, height: 4.0)
        let epoch = CGPoint(x: 2.0, y: 3.0)
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        let region = Region(rect: rect, epoch: epoch, context: context)
        XCTAssertEqual(region.x, Int32(rect.origin.x))
        XCTAssertEqual(region.y, Int32(rect.origin.y))
        XCTAssertEqual(region.width, Int32(rect.size.width))
        XCTAssertEqual(region.height, Int32(rect.size.height))
        XCTAssertEqual(region.epochX, Int32(epoch.x))
        XCTAssertEqual(region.epochY, Int32(epoch.y))
    }
}
