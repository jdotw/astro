//
//  ImportTests.swift
//  AstroTests
//
//  Created by James Wilson on 22/7/2023.
//

import XCTest

@testable import Astro

final class ImportTests: XCTestCase {
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func test20230629DataSet() throws {
        let url = Bundle.main.url(forResource: "20230629", withExtension: nil)!
        let request = ImportRequest(url: url)
        let files = try request.buildFileList(from: [url])
        XCTAssertEqual(files.count, 18) // There are 18 files in this data set
    }
}
