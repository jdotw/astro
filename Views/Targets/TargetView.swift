//
//  SessionView.swift
//  Astro
//
//  Created by James Wilson on 12/7/2023.
//

import SwiftUI

struct TargetView: View {
    var target: Target
    @Binding var navStackPath: [File]

    @AppStorage("targetFileBrowserViewMode") private var fileViewMode: FileBrowserViewMode = .table

    var body: some View {
        VStack {
            FileBrowser(source: .target(target), columns: [.timestamp, .type, .filter], navStackPath: $navStackPath, viewMode: $fileViewMode)
        }
        .navigationTitle(target.name)
    }
}

extension TargetView {
    var files: [File] {
        guard let files = target.files as? Set<File>
        else {
            return []
        }
        return Array(files)
    }
}
