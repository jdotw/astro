//
//  PixInsightCalibrationOperation.swift
//  Astro
//
//  Created by James Wilson on 12/11/2023.
//

import Foundation

class PixInsightCalibrationOperation: Operation, ExternalProcessingOperation {
    let files: [File]
    let masterFlat: URL?
    var error: Error?
    let uuid = UUID()

    required init(files: [File]) {
        self.files = files
        self.masterFlat = nil
    }

    init(files: [File], masterFlat: URL) {
        self.files = files
        self.masterFlat = masterFlat
        super.init()
    }

    var outputURL: URL {
        FileManager.default.temporaryDirectory.appending(path: uuid.uuidString)
    }

    private var jsScript: String? {
        guard let templateURL = Bundle.main.url(forResource: "PixInsightCalibrationScriptTemplate", withExtension: "js"),
              let template = try? String(contentsOf: templateURL),
              let masterFlat
        else { return nil }

        var script = String()
        script.append("var P = new ImageCalibration;\n")
        script.append("P.targetFrames = [ // enabled, path\n")
        files.forEach { file in
            script.append("    [true, \"\(file.fitsURL.path(percentEncoded: false))\"],\n")
        }
        script.append("];\n")
        script.append(template)

        script.append("P.masterFlatPath = \"\(masterFlat.path(percentEncoded: false))\";\n")
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

        let pi = PixInsightProcessor()
        let output = pi.runScript(atURL: scriptURL)
        print("OUTPUT: ", output)
    }
}
