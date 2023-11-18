//
//  PixInsightRegistrationOperation.swift
//  Astro
//
//  Created by James Wilson on 18/11/2023.
//

import Foundation

class PixInsightRegistrationOperation: Operation {
    let fileURLs: [URL]
    let referenceFileURL: URL
    var error: Error?
    let uuid = UUID()

    init(fileURLs: [URL], referenceFileURL: URL) {
        self.fileURLs = fileURLs
        self.referenceFileURL = referenceFileURL
        super.init()
    }

    var outputURL: URL {
        FileManager.default.temporaryDirectory.appending(path: uuid.uuidString)
    }

    private var jsScript: String? {
        guard let templateURL = Bundle.main.url(forResource: "PixInsightRegistrationScriptTemplate", withExtension: "js"),
              let template = try? String(contentsOf: templateURL)
        else { return nil }

        var script = String()
        script.append("var P = new StarAlignment;\n")
        script.append("P.outputDirectory = \"\(outputURL.path(percentEncoded: false))\";\n")
        script.append("P.referenceImage = \"\(referenceFileURL.path(percentEncoded: false))\";\n")
        script.append("P.targets = [ // enabled, isFile, image\n")
        fileURLs.forEach { url in
            script.append("    [true, true, \"\(url.path(percentEncoded: false))\"],\n")
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

        let pi = PixInsightProcessor()
        let output = pi.runScript(atURL: scriptURL)
        print("OUTPUT: ", output)
    }
}
