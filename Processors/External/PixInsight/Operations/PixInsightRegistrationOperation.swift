//
//  PixInsightRegistrationOperation.swift
//  Astro
//
//  Created by James Wilson on 18/11/2023.
//

import CoreData
import Foundation

class PixInsightRegistrationOperation: Operation {
    let files: [File]
    let referenceFile: File
    var error: Error?
    let uuid = UUID()

    init(files: [File], referenceFile: File) {
        self.files = files
        self.referenceFile = referenceFile
        super.init()
    }

    private var outputURL: URL {
        FileManager.default.temporaryDirectory.appending(path: uuid.uuidString)
    }

    var outputFileObjectIDs: [NSManagedObjectID] = []

    private var jsScript: String? {
        guard let templateURL = Bundle.main.url(forResource: "PixInsightRegistrationScriptTemplate", withExtension: "js"),
              let template = try? String(contentsOf: templateURL)
        else { return nil }

        var script = String()
        script.append("var P = new StarAlignment;\n")
        script.append("P.outputDirectory = \"\(outputURL.path(percentEncoded: false))\";\n")
        script.append("P.referenceImage = \"\(referenceFile.fitsURL.path(percentEncoded: false))\";\n")
        script.append("P.targets = [ // enabled, isFile, image\n")
        files.forEach { file in
            script.append("    [true, true, \"\(file.fitsURL.path(percentEncoded: false))\"],\n")
        }
        script.append("];\n")
        script.append(template)
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

                let waitSema = DispatchSemaphore(value: 0)
                PersistenceController.shared.container.performBackgroundTask { context in
                    guard let outputURLContents = try? FileManager.default.contentsOfDirectory(at: outputURL, includingPropertiesForKeys: nil) else { return }
                    for outputFile in outputURLContents {
                        if outputFile.pathExtension != "xisf" {
                            continue
                        }
                        guard let originalFile = self.files.first(where: { $0.fitsURL.lastPathComponent == outputFile.lastPathComponent }) else {
                            print("CANT FIND ORIGINAL FOR: ", outputFile)
                            continue
                        }
                        let importer = XISFFileImporter(url: outputFile,
                                                        context: context)
                        importer.addToSession = false
                        importer.addToTarget = false
                        do {
                            let importedFile = try importer.importFile { file in
                                let importedFileName = "Registered_\(originalFile.name)"
                                file.name = importedFileName
                                file.timestamp = Date()
                                file.status = .registered
                                if let calibratedFileObjectID = self.files.first(where: { $0.fitsURL.lastPathComponent == outputFile.lastPathComponent })?.objectID,
                                   let calibratedFile = context.object(with: calibratedFileObjectID) as? File
                                {
                                    let derivation = FileDerivation(context: context)
                                    derivation.timestamp = Date()
                                    derivation.input = calibratedFile
                                    derivation.output = file
                                    derivation.process = .registration

                                    let refereceDerivation = FileDerivation(context: context)
                                    refereceDerivation.timestamp = Date()
                                    refereceDerivation.input = context.object(with: self.referenceFile.objectID) as! File
                                    refereceDerivation.output = file
                                    refereceDerivation.process = .registrationReference
                                }
                            }

                            if let importedFile {
                                self.outputFileObjectIDs.append(importedFile.objectID)

                                // Process the imported image (create preview, etc)
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
                                print("Error importing integrated image: ", error)
                            }
                        }
                    }
                    waitSema.signal()
                }
                waitSema.wait()
            }

        } catch {
            self.error = error
        }
    }
}
