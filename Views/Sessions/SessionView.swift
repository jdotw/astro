//
//  SessionView.swift
//  Astro
//
//  Created by James Wilson on 12/7/2023.
//

import SwiftUI

struct SessionView: View {
    var session: Session
    @Binding var navStackPath: [File]

    @AppStorage("sessionFileBrowserViewMode") private var fileViewMode: FileBrowserViewMode = .approve

    var body: some View {
        VStack {
            FileBrowser(source: .session(session),
                        navStackPath: $navStackPath,
                        viewMode: $fileViewMode)
        }
    }
}

extension SessionView {
    var files: [File] {
        guard let files = session.files as? Set<File>
        else {
            return []
        }
        return Array(files)
    }
}
