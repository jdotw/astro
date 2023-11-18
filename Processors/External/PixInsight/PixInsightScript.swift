//
//  PixInsightScript.swift
//  Astro
//
//  Created by James Wilson on 12/11/2023.
//

import Foundation

struct PixInsightScript {
    static func scriptToRun(jsScript: URL) -> String {
        var script = String()
        script.append("run -x \"\(jsScript.path(percentEncoded: false))\"\n")
        return script
    }

    static func scriptToRun(jsScript: URL, savingImage: String, to destination: URL) -> String {
        var script = String()
        script.append(scriptToRun(jsScript: jsScript))
        script.append("save integration -p=\"\(destination.path(percentEncoded: false))\" --nodialog --nomessages --noverify\n")
        return script
    }
}
