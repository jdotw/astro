//
//  ImportFileListTests.swift
//  AstroTests
//
//  Created by James Wilson on 22/7/2023.
//

import XCTest

@testable import Astro

final class ImportFileListTests: XCTestCase {
    override func setUpWithError() throws {}

    override func tearDownWithError() throws {}

    func testBuildFileListWithDirectoryURL() throws {
        guard let url = Bundle.main.resourceURL else {
            XCTFail("Failed to get resource URL")
            return
        }
        let files = try ImportFileList.buildFileList(at: url)
        XCTAssertFalse(files.isEmpty)
        XCTAssertFalse(files.contains(where: { x in
            x == url
        }))
    }

    func testBuildFileListWithFileURL() throws {
        let url = Bundle.main.url(forResource: "SGPro", withExtension: "fit")!
        let files = try ImportFileList.buildFileList(at: url)
        XCTAssertEqual(files.count, 1)
        XCTAssertTrue(files.contains(where: { x in
            x == url
        }))
    }

    func testInitializer() throws {
        guard let url = Bundle.main.resourceURL else {
            XCTFail("Failed to get resource URL")
            return
        }
        let fileList = try ImportFileList(at: url)
        XCTAssertEqual(fileList.baseURL, url)
        XCTAssertFalse(fileList.files.isEmpty)
    }
}
