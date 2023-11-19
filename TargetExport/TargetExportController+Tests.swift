//
//  TargetExportControllerTests.swift
//  AstroTests
//
//  Created by James Wilson on 19/11/2023.
//

@testable import Astro
import XCTest

final class TargetExportControllerTests: XCTestCase {
    var context: NSManagedObjectContext!

    override func setUpWithError() throws {
        context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
    }

    override func tearDownWithError() throws {}

    func testFileNameTimestampWithKnownDate() throws {
        let controller = TargetExportController.shared
        let date = Date(timeIntervalSince1970: 1700353528)
        let dateString = controller.fileNameTimestamp(forDate: date)
        XCTAssertEqual(dateString, "20231119")
    }

    func testFileNameTimestampWithoutDate() throws {
        let controller = TargetExportController.shared
        let dateString = controller.fileNameTimestamp(forDate: nil)
        XCTAssertEqual(dateString, "unknown")
    }

    private func fileWithTimestamp(_ date: Date) -> File {
        let file = File(context: context)
        file.timestamp = date
        return file
    }

    func testIntegratedFileName() throws {
        var files = [TargetExportRequestFile]()
        let day = TimeInterval(integerLiteral: 86400)
        let initialDate = Date(timeIntervalSince1970: 1700353528)
        let oldestDate = initialDate.addingTimeInterval(-2 * day)
        let newestDate = initialDate.addingTimeInterval(2 * day)

        files.append(TargetExportRequestFile(source: fileWithTimestamp(initialDate),
                                             type: .light,
                                             status: .registered,
                                             url: nil))
        files.append(TargetExportRequestFile(source: fileWithTimestamp(oldestDate),
                                             type: .light,
                                             status: .registered,
                                             url: nil))
        files.append(TargetExportRequestFile(source: fileWithTimestamp(initialDate),
                                             type: .light,
                                             status: .registered,
                                             url: nil))
        files.append(TargetExportRequestFile(source: fileWithTimestamp(newestDate),
                                             type: .light,
                                             status: .registered,
                                             url: nil))
        files.append(TargetExportRequestFile(source: fileWithTimestamp(initialDate),
                                             type: .light,
                                             status: .registered,
                                             url: nil))

        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        let filter = Filter(context: context)
        filter.name = "TestFilter"
        let earliestDateString = TargetExportController.shared.fileNameTimestamp(forDate: oldestDate)
        let latestDateString = TargetExportController.shared.fileNameTimestamp(forDate: newestDate)
        let pattern = "^\(filter.name.localizedCapitalized)-Integrated-\(files.count)files-\(earliestDateString)-\(latestDateString)$"

        let integratedFileName = TargetExportController.shared.integratedFileName(forFiles: files, filter: filter)
        let matches = try integratedFileName.matches(of: Regex(pattern))

        XCTAssertEqual(matches.count, 1)
    }
}
