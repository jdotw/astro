//
//  SessionView.swift
//  Astro
//
//  Created by James Wilson on 12/7/2023.
//

import SwiftUI

struct SessionView: View {
    var session: Session

    @State private var selectedFileIDs: Set<File.ID> = []
    @State private var sortOrder: [KeyPathComparator<File>] = [
        .init(\.timestamp, order: SortOrder.reverse)
    ]
    @State private var focusedFile: File?
    @Binding var navStackPath: [File]
    @AppStorage("sessionFileListViewMode") private var fileViewMode: FileListModePicker.ViewMode = .table

    var body: some View {
        VStack {
            switch fileViewMode {
            case .table:
                HStack {
                    Table(files, selection: $selectedFileIDs, sortOrder: $sortOrder) {
                        TableColumn("Timestamp", value: \.timestamp) { file in
                            Text(file.timestamp.formatted(date: .omitted, time: .shortened))
                        }
                        .width(100)

                        TableColumn("Target", value: \.target!.name)
                            .width(100)

                        TableColumn("Type", value: \.type) { file in
                            Text(file.type.localizedCapitalized)
                        }
                        .width(50)

                        TableColumn("Filter", value: \.filter!) { file in
                            Text(file.filter?.localizedCapitalized ?? "N/A")
                        }
                        .width(50)
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
                }
            case .gallery:
                MultiFileView(files: session.files as? Set<File> ?? [], navStackPath: $navStackPath)
            }
        }
        .toolbar {
            ToolbarItem {
                FileListModePicker(mode: $fileViewMode)
            }
        }
    }
}

extension SessionView {
    var files: [File] {
        guard let files = session.files as? Set<File>
        else {
            return []
        }
        return files.sorted(using: sortOrder)
    }

    var selectedFiles: Set<File> {
        if let files = session.files as? Set<File> {
            return files.filter { selectedFileIDs.contains($0.id) }
        } else {
            return []
        }
    }
}
