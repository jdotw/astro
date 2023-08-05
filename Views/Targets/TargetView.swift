//
//  SessionView.swift
//  Astro
//
//  Created by James Wilson on 12/7/2023.
//

import SwiftUI

struct TargetView: View {
    var target: Target

    @State private var sortOrder: [KeyPathComparator<File>] = [
        .init(\.filter, order: SortOrder.forward),
        .init(\.timestamp, order: SortOrder.reverse)
    ]

    @State private var processedImage: NSImage?
    @Binding var navStackPath: [File]

    @State private var selectedFileIDs: Set<File.ID> = [] // Table only

    @ObservedObject private var imageProcessor = ImageProcessor()

    @AppStorage("targetFileListViewMode") private var fileViewMode: FileListModePicker.ViewMode = .table

    var body: some View {
        HStack {
            switch fileViewMode {
            case .table:
                Table(files, selection: $selectedFileIDs, sortOrder: $sortOrder) {
                    TableColumn("Filter", value: \.filter!) { file in
                        Text(file.filter?.localizedCapitalized ?? "N/A")
                    }
                    .width(min: 20.0, ideal: 30.0, max: nil)

                    TableColumn("Timestamp", value: \.timestamp) {
                        Text($0.timestamp.formatted(date: .abbreviated, time: .shortened))
                    }
                    .width(min: 100.0, ideal: 150.0, max: nil)

                    TableColumn("Target", value: \.target!.name)
                        .width(min: 50.0, ideal: 100.0, max: nil)

                    TableColumn("Type", value: \.type) { file in
                        Text(file.type.localizedCapitalized)
                    }
                    .width(min: 20.0, ideal: 50.0, max: nil)
                }
                .contextMenu(forSelectionType: File.ID.self, menu: { _ in
                    //                    Button("Rename", action: { print("RENAME \(items)") })
                    //                    Button("Delete", action: { print("DELETE \(items)") })
                }, primaryAction: { _ in
                    if selectedFiles.count == 1, let selectedFile = selectedFiles.first {
                        navStackPath.append(selectedFile)
                    }
                })
                VStack {
                    MultiFileView(files: selectedFiles, navStackPath: $navStackPath)
                }
                .frame(width: 250.0)
            case .gallery:
                FileView(files: target.files as? Set<File> ?? [], navStackPath: $navStackPath)
            }
        }
        .toolbar {
            ToolbarItem {
                Button(action: {
                    imageProcessor.setFiles(selectedFiles)
                    imageProcessor.processFrames { result in
                        let rep = NSCIImageRep(ciImage: result)
                        let nsImage = NSImage(size: rep.size)
                        nsImage.addRepresentation(rep)
                        self.processedImage = nsImage
                    }
                }) {
                    Label("Register", systemImage: "square.stack.3d.down.right")
                }
            }
            ToolbarItem {
                FileListModePicker(mode: $fileViewMode)
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
        return files.sorted(using: sortOrder)
    }

    var selectedFiles: Set<File> {
        if let files = target.files as? Set<File> {
            return files.filter { selectedFileIDs.contains($0.id) }
        } else {
            return []
        }
    }
}
