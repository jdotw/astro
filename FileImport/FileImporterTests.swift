//
//  FileImporterTests.swift
//  AstroTests
//
//  Created by James Wilson on 21/7/2023.
//

@testable import Astro
import XCTest

final class FileImporterTests: XCTestCase {
    var context: NSManagedObjectContext!

    override func setUpWithError() throws {
        context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
    }

    override func tearDownWithError() throws {}

    func testFITFileExtension() throws {
        let url = URL(fileURLWithPath: "/Users/test/Downloads/NGC253.fit")
        guard let importer = FileImporter.importer(forURL: url, context: context) else {
            XCTFail("No importer returned")
            return
        }
        XCTAssertTrue(importer is FITSFileImporter)
    }

    func testFITSFileExtension() throws {
        let url = URL(fileURLWithPath: "/Users/test/Downloads/NGC253.fits")
        guard let importer = FileImporter.importer(forURL: url, context: context) else {
            XCTFail("No importer returned")
            return
        }
        XCTAssertTrue(importer is FITSFileImporter)
    }
}
