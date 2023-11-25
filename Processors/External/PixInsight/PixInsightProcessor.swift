//
//  PixInsightInstance.swift
//  Astro
//
//  Created by James Wilson on 12/11/2023.
//

import Foundation

class PixInsightInstance: ExternalProcessor {
    var slot: Int? = nil
    var automationMode = true
    var forceExit = true
    
    private var arguments: [String] {
        var arguments = [String]()
        if let slot { arguments.append("-y=\(slot)") }
        else { arguments.append("-n") }
        if automationMode { arguments.append("--automation-mode") }
        if forceExit { arguments.append("--force-exit") }
        return arguments
    }
    
    func runScript(atURL url: URL) -> String {
        let task = Process()
        let pipe = Pipe()
            
        task.standardOutput = pipe
        task.standardError = pipe
        task.launchPath = "/Applications/PixInsight/PixInsight.app/Contents/MacOS/PixInsight"
        var arguments = self.arguments
        if let slot {
            // Execute via IPC
            arguments.append("-x=\"\(slot):\(url.path(percentEncoded: false))\"")
        } else {
            // Run in spawned instance
            arguments.append("-r=\"\(url.path(percentEncoded: false))\"")
        }
        print("ARGS: ", arguments)
        task.arguments = arguments
        task.standardInput = nil
        task.currentDirectoryURL = FileManager.default.homeDirectoryForCurrentUser
        task.environment = ProcessInfo.processInfo.environment
            
        task.launch()
            
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)!
            
        return output
    }
}
