//
//  PixInsightPreProcessingOperation.swift
//  Astro
//
//  Created by James Wilson on 12/11/2023.
//

import Foundation

class PixInsightPreProcessingOperation: Operation, ExternalProcessingOperation {
    let files: [File]
    let error: Error?

    required init(files: [File]) {
        self.files = files
        self.error = nil
    }

    override func main() {
        // 1. Get Batches
        let batches = TargetFileBatch.batches(forFiles: files)
        var calibratedFileURLs = [URL]()

        // 2. For each filter in each batch
        batches.forEach { batch in
            batch.uniqueFilters.forEach { filter in
                //  - Integrated calibration frames
                guard let flatsFiles = batch.flatFilesByFilter[filter] else { return }
                let integrationOp = PixInsightIntegrationOperation(files: flatsFiles)
                print("INTEGRATING FLATS for \(filter.name) in batch \(batch.name) using \(flatsFiles.count) flat files")
                integrationOp.main()

                //  - Calibrate light frames
                guard let lightFiles = batch.lightFilesByFilter[filter],
                      let masterFlat = integrationOp.outputURL
                else { return }
                let calOp = PixInsightCalibrationOperation(files: lightFiles,
                                                           masterFlat: masterFlat)
                calOp.main()

                calibratedFileURLs.append(contentsOf: lightFiles.map { file in
                    calOp.outputURL.appending(path: file.fitsURL.lastPathComponent)
                })
            }
        }

        // 3. Register light frames
        print("calibratedURLs: ", calibratedFileURLs)

        // 4. For each unique filter (across all batches)
        let allFilters = batches.flatMap { $0.uniqueFilters.map { $0 } }
        allFilters.forEach { filter in
            var fileNames = [String]()
            batches.forEach { batch in
                guard let lightFiles = batch.lightFilesByFilter[filter] else { return }
                fileNames.append(contentsOf: lightFiles.map { $0.fitsURL.lastPathComponent })
            }

            let lightFiles = calibratedFileURLs.filter { url in
                fileNames.contains { file in
                    file == url.lastPathComponent
                }
            }

            let integrationOp = PixInsightIntegrationOperation(fileURLs: lightFiles)
            print("INTEGRATING LIGHTS for \(filter.name) using \(lightFiles.count) light files")
            integrationOp.main()
        }
    }
}
