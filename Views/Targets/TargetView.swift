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
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "\(target.name)"
        if panel.runModal() == .OK {
            let exportRequest = TargetExportRequest(context: viewContext)
            exportRequest.timestamp = Date()
            exportRequest.url = panel.url!
            try! FileManager.default.createDirectory(at: exportRequest.url, withIntermediateDirectories: false)
            exportRequest.target = target
            exportRequest.bookmark = try! exportRequest.url.bookmarkData(options: .withSecurityScope)
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
            openWindow(value: exportRequest.id)
            do {
                try TargetExportController.shared.performExport(request: exportRequest) {
                    exportRequest.completed = true
                    do {
                        try viewContext.save()
                    } catch {
                        exportRequest.error = error.localizedDescription
                    }
                }
            } catch {
                exportRequest.error = error.localizedDescription
            }
        }
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
