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

    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.openWindow) private var openWindow

    private func exportTarget() {
        let exportRequest = TargetExportRequest(context: viewContext)
        exportRequest.timestamp = Date()
        exportRequest.target = target
        exportRequest.status = .notStarted
        do {
            try viewContext.save()
        } catch {
            fatalError(error.localizedDescription)
        }
        openWindow(value: exportRequest.id)
    }

    var body: some View {
        VStack {
            FileBrowser(source: .target(target), columns: [.timestamp, .type, .filter], navStackPath: $navStackPath, viewMode: $fileViewMode)
        }
        .navigationTitle(target.name)
        .toolbar {
            ToolbarItemGroup {
                Button(action: {
                    exportTarget()
                }) {
                    Label("Export", systemImage: "square.and.arrow.up.on.square")
                }
            }
        }
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
