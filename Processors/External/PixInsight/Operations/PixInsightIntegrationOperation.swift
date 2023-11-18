//
//  PixInsightIntegrationOperation.swift
//  Astro
//
//  Created by James Wilson on 12/11/2023.
//

import Foundation

class PixInsightIntegrationOperation: Operation, ExternalProcessingOperation {
    let files: [File]
    let fileURLs: [URL]
    var error: Error?
    var outputURL: URL?

    required init(files: [File]) {
        self.files = files
        self.fileURLs = []
    }

    init(fileURLs: [URL]) {
        self.files = []
        self.fileURLs = fileURLs
        super.init()
    }

    private var jsScript: String? {
        guard let templateURL = Bundle.main.url(forResource: "PixInsightIntegrationScriptTemplate", withExtension: "js"),
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
        print("YEAH: ", files)

        let uuid = UUID()

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

        let pi = PixInsightProcessor()
        let output = pi.runScript(atURL: scriptURL)

        outputURL = outputImageURL

        print("OUTPUT: ", output)
    }
}
