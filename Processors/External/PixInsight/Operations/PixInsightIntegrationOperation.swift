//
//  PixInsightIntegrationOperation.swift
//  Astro
//
//  Created by James Wilson on 12/11/2023.
//

import CoreData
import Foundation

enum PixInsightIntegrationMode {
    case flats
    case lights
}

class PixInsightIntegrationOperation: Operation, ExternalProcessingOperation {
    let files: [File]
    let fileURLs: [URL]
    var error: Error?
    var outputURL: URL?
    var outputFileObjectID: NSManagedObjectID?
    var mode: PixInsightIntegrationMode = .lights

    required init(files: [File]) {
        self.files = files
        self.fileURLs = []
    }

    init(files: [File], mode: PixInsightIntegrationMode) {
        self.files = files
        self.fileURLs = []
        self.mode = mode
        super.init()
    }

    init(fileURLs: [URL], mode: PixInsightIntegrationMode) {
        self.files = []
        self.fileURLs = fileURLs
        self.mode = mode
        super.init()
    }

    private var jsScriptTemplateName: String {
        switch mode {
        case .flats:
            return "PixInsightFlatsIntegrationScriptTemplate"
        case .lights:
            return "PixInsightLightsIntegrationScriptTemplate"
        }
    }

    private var jsScript: String? {
        guard let templateURL = Bundle.main.url(forResource: jsScriptTemplateName, withExtension: "js"),
              let template = try? String(contentsOf: templateURL)
        else { return nil }

        var script = String()
        script.append("var P = new ImageIntegration;\n")
        script.append("P.images = [ // enabled, path, drizzlePath, localNormalizationDataPath\n")
        files.forEach { file in
            script.append("    [true, \"\(file.fitsURL.path(percentEncoded: false))\", \"\", \"\"],\n")
        }
        fileURLs.forEach { url in
            script.append("    [true, \"\(url.path(percentEncoded: false))\", \"\", \"\"],\n")
        }
        script.append("];\n")
        script.append(template)
        script.append("P.executeGlobal();\n")
        return script
    }

    override func main() {
        let uuid = UUID()

        guard let referenceFile = files.first else {
            error = PixInsightIntegrationError.noFiles
            return
        }

        // Look for an existing artefact
        if mode == .flats {
            let artefactRequest = NSFetchRequest<File>(entityName: "File")
            artefactRequest.predicate = NSPredicate(format: "SUBQUERY(derivedFrom, $derivedFrom, $derivedFrom.input IN %@).@count == derivedFrom.@count AND derivedFrom.@count == %d", NSSet(array: files), files.count)
            artefactRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
            let waitSema = DispatchSemaphore(value: 0)
            var didFindCachedCandidate = false
            PersistenceController.shared.container.performBackgroundTask { context in
                if let result = try? context.fetch(artefactRequest).first {
                    print("FOUND CACHED: ", result)
                    self.outputURL = result.fitsURL
                    self.outputFileObjectID = result.objectID
                    didFindCachedCandidate = true
                } else {
                    print("NO CACHE :/")
                }
                waitSema.signal()
            }
            waitSema.wait()
            if didFindCachedCandidate {
                print("USING CACHED FILE AND BAILING EARLY!")
                return
            }
        }

        let jsScriptURL = FileManager.default.temporaryDirectory.appending(path: "\(uuid.uuidString).js")
        print("JS URL: ", jsScriptURL)
        do {
            try jsScript?.write(to: jsScriptURL, atomically: true, encoding: .utf8)
        } catch {
            self.error = error
        }

        let outputImageURL = FileManager.default.temporaryDirectory.appending(path: "\(uuid.uuidString).xisf")
        print("OUTPUT URL: ", outputImageURL)

        let script = PixInsightScript.scriptToRun(jsScript: jsScriptURL,
                                                  savingImage: "integration",
                                                  to: outputImageURL)
        let scriptURL = FileManager.default.temporaryDirectory.appending(path: "\(uuid.uuidString).scp")
        print("SCRIPT URL: ", scriptURL)
        do {
            try script.write(to: scriptURL, atomically: true, encoding: .utf8)
        } catch {
            self.error = error
        }

        let fileType = referenceFile.type.rawValue.localizedCapitalized
        let filter = referenceFile.filter.name.localizedCapitalized
        let sortedFiles = files.sorted { a, b in
            a.timestamp < b.timestamp
        }
        guard let newestFile = sortedFiles.last,
              let oldestFile = sortedFiles.first
        else {
            error = PixInsightIntegrationError.noFiles
            return
        }
        let newestFileDateString = newestFile.sessionDateString
        let oldestFileDateString = oldestFile.sessionDateString
        var fileDateRangeString: String
        if oldestFileDateString == newestFileDateString {
            fileDateRangeString = newestFileDateString
        } else {
            fileDateRangeString = "\(oldestFileDateString)-to-\(newestFileDateString)"
        }
        let importedFileName = "Integration-\(fileType)-\(filter)-\(fileDateRangeString).xisf"
        do {
            try PixInsightController.shared.withInstance { pi in
                let output = pi.runScript(atURL: scriptURL)
                outputURL = outputImageURL
                print("OUTPUT: ", output)

                if let outputURL {
                    PersistenceController.shared.container.performBackgroundTask { context in
                        let importer = XISFFileImporter(url: outputURL,
                                                        context: context)
                        importer.addToSession = false
                        do {
                            let importedFile = try importer.importFile { file in
                                file.name = importedFileName
                                file.timestamp = Date()
                                switch self.mode {
                                case .flats:
                                    file.status = .master
                                case .lights:
                                    file.status = .integrated
                                }
                                let fileObjectIDs = self.files.map { $0.objectID }
                                fileObjectIDs.forEach { inputFileID in
                                    let inputFile = context.object(with: inputFileID) as! File
                                    let derivation = FileDerivation(context: context)
                                    derivation.timestamp = Date()
                                    derivation.input = inputFile
                                    derivation.output = file
                                    derivation.process = .integration
                                }
                            }

                            if let importedFile {
                                self.outputFileObjectID = importedFile.objectID

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
                }
            }
        } catch {
            self.error = error
        }
    }
}

enum PixInsightIntegrationError: Error {
    case noFiles
}
