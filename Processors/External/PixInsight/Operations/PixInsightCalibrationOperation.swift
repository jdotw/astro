//
//  PixInsightCalibrationOperation.swift
//  Astro
//
//  Created by James Wilson on 12/11/2023.
//

import Foundation

class PixInsightCalibrationOperation: Operation, ExternalProcessingOperation {
    let files: [File]
    let masterFlat: File
    var error: Error?
    let uuid = UUID()

    init(files: [File], masterFlat: File) {
        self.files = files
        self.masterFlat = masterFlat
        super.init()
    }

    var outputURL: URL {
        FileManager.default.temporaryDirectory.appending(path: uuid.uuidString)
    }

    private var jsScript: String? {
        guard let templateURL = Bundle.main.url(forResource: "PixInsightCalibrationScriptTemplate", withExtension: "js"),
              let template = try? String(contentsOf: templateURL)
        else { return nil }

        var script = String()
        script.append("var P = new ImageCalibration;\n")
        script.append("P.targetFrames = [ // enabled, path\n")
        files.forEach { file in
            script.append("    [true, \"\(file.fitsURL.path(percentEncoded: false))\"],\n")
        }
        script.append("];\n")
        script.append(template)

        script.append("P.masterFlatPath = \"\(masterFlat.fitsURL.path(percentEncoded: false))\";\n")
        script.append("P.outputDirectory = \"\(outputURL.path(percentEncoded: false))\";\n")

        script.append("P.executeGlobal();\n")
        return script
    }

    override func main() {
        let jsScriptURL = FileManager.default.temporaryDirectory.appending(path: "\(uuid.uuidString).js")
        print("JS URL: ", jsScriptURL)
        do {
            try jsScript?.write(to: jsScriptURL, atomically: true, encoding: .utf8)
        } catch {
            self.error = error
            return
        }

        let script = PixInsightScript.scriptToRun(jsScript: jsScriptURL)
        let scriptURL = FileManager.default.temporaryDirectory.appending(path: "\(uuid.uuidString).scp")
        print("SCRIPT URL: ", scriptURL)
        do {
            try script.write(to: scriptURL, atomically: true, encoding: .utf8)
        } catch {
            self.error = error
            return
        }

        let outputURL = self.outputURL
        do {
            try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: false)
        } catch {
            self.error = error
            return
        }
        print("CAL OUTPUT: ", outputURL)

        do {
            try PixInsightController.shared.withInstance { pi in
                let output = pi.runScript(atURL: scriptURL)
                print("OUTPUT: ", output)

                PersistenceController.shared.container.performBackgroundTask { context in

                    self.files.forEach { inputFile in
                        let sourceURL = outputURL.appending(path: inputFile.fitsURL.lastPathComponent)
                            .deletingPathExtension()
                            .appendingPathExtension("xisf")

                        let importer = XISFFileImporter(url: sourceURL,
                                                        context: context)
                        importer.addToSession = false
                        importer.addToTarget = false
                        do {
                            let importedFile = try importer.importFile { file in
                                file.name = outputURL.appending(path: "Calibrated-\(inputFile.name)")
                                    .deletingPathExtension()
                                    .appendingPathExtension("xisf")
                                    .lastPathComponent
                                file.timestamp = Date()
                                file.status = .calibrated

                                // Create a record for the light frame thats
                                // been used to derive this calibrated frame
                                let inputLightFile = context.object(with: inputFile.objectID) as! File
                                let lightDerivation = FileDerivation(context: context)
                                lightDerivation.timestamp = Date()
                                lightDerivation.input = inputLightFile
                                lightDerivation.output = file
                                lightDerivation.process = .calibration

                                // Create a record for the master flat thats
                                // been used to derive this calibrated frame
                                let inputFlatFile = context.object(with: self.masterFlat.objectID) as! File
                                let flatDerivation = FileDerivation(context: context)
                                flatDerivation.timestamp = Date()
                                flatDerivation.input = inputFlatFile
                                flatDerivation.output = file
                                flatDerivation.process = .calibration
                            }

                            // Process the imported image (create preview, etc)
                            if let importedFile {
                                let processor = FileProcessOperation(fileObjectID: importedFile.objectID)
                                FileProcessController.shared.queue.addOperation(processor)
                            }
                        } catch {
                            self.error = error
                            switch error {
                            case FileImportError.alreadyExists(let file):
                                if file.previewURL == nil {
                                    // Exists but has no preview, process it
                                    FileProcessController.process(fileObjectID: file.objectID)
                                    let processor = FileProcessOperation(fileObjectID: file.objectID)
                                    FileProcessController.shared.queue.addOperation(processor)
                                }
                            default:
                                print("Error importing calibrated image: ", error)
                            }
                        }
                    }
                }
            }
        } catch {
            self.error = error
        }
    }
}
