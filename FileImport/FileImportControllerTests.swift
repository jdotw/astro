//
//  FileImportControllerTests.swift
//  AstroTests
//
//  Created by James Wilson on 22/7/2023.
//

import XCTest

@testable import Astro

final class FileImportControllerTests: XCTestCase {
    override func setUpWithError() throws {}

    override func tearDownWithError() throws {}

    func testBuildFileListsWithDirectory() throws {
        let url = Bundle.main.resourceURL!.absoluteURL
        let controller = FileImportController()
        let fileList = try controller.buildFileLists(fromURLs: [url])
        XCTAssertEqual(fileList.count, 1)
        XCTAssertEqual(fileList.first!.baseURL, url)
        XCTAssertGreaterThan(fileList.first!.files.count, 2)
    }
}
